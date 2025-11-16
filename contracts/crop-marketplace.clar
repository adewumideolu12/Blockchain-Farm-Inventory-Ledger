(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u500))
(define-constant err-unauthorized (err u501))
(define-constant err-invalid-amount (err u502))
(define-constant err-listing-inactive (err u503))
(define-constant err-insufficient-inventory (err u504))
(define-constant err-self-purchase (err u505))

(define-data-var next-listing-id uint u1)

(define-map marketplace-listings
  uint
  {
    farmer: principal,
    crop-type: (string-ascii 50),
    quantity-available: uint,
    price-per-unit: uint,
    created-at: uint,
    active: bool,
    total-sold: uint
  }
)

(define-map farmer-active-listings
  { farmer: principal, crop-type: (string-ascii 50) }
  { listing-id: uint, quantity: uint }
)

(define-public (create-listing
  (crop-type (string-ascii 50))
  (quantity uint)
  (price-per-unit uint)
)
  (let
    (
      (listing-id (var-get next-listing-id))
      (farmer tx-sender)
      (inventory (contract-call? .Blockchain-Farm-Inventory-Ledger get-farmer-inventory farmer crop-type))
    )
    (asserts! (> quantity u0) err-invalid-amount)
    (asserts! (> price-per-unit u0) err-invalid-amount)
    (asserts! (>= (get available-quantity inventory) quantity) err-insufficient-inventory)
    
    (map-set marketplace-listings listing-id {
      farmer: farmer,
      crop-type: crop-type,
      quantity-available: quantity,
      price-per-unit: price-per-unit,
      created-at: stacks-block-height,
      active: true,
      total-sold: u0
    })
    
    (map-set farmer-active-listings 
      { farmer: farmer, crop-type: crop-type }
      { listing-id: listing-id, quantity: quantity }
    )
    
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

(define-public (purchase-from-listing (listing-id uint) (quantity uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace-listings listing-id) err-not-found))
      (buyer tx-sender)
      (farmer (get farmer listing))
    )
    (asserts! (get active listing) err-listing-inactive)
    (asserts! (not (is-eq buyer farmer)) err-self-purchase)
    (asserts! (<= quantity (get quantity-available listing)) err-invalid-amount)
    (asserts! (> quantity u0) err-invalid-amount)
    
    (map-set marketplace-listings listing-id (merge listing {
      quantity-available: (- (get quantity-available listing) quantity),
      total-sold: (+ (get total-sold listing) quantity),
      active: (> (- (get quantity-available listing) quantity) u0)
    }))
    
    (ok true)
  )
)

(define-public (update-listing-price (listing-id uint) (new-price uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace-listings listing-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get farmer listing)) err-unauthorized)
    (asserts! (> new-price u0) err-invalid-amount)
    
    (map-set marketplace-listings listing-id (merge listing {
      price-per-unit: new-price
    }))
    
    (ok true)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace-listings listing-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get farmer listing)) err-unauthorized)
    
    (map-set marketplace-listings listing-id (merge listing {
      active: false
    }))
    
    (ok true)
  )
)

(define-read-only (get-listing (listing-id uint))
  (map-get? marketplace-listings listing-id)
)

(define-read-only (get-farmer-listing (farmer principal) (crop-type (string-ascii 50)))
  (map-get? farmer-active-listings { farmer: farmer, crop-type: crop-type })
)

(define-read-only (get-total-listings)
  (- (var-get next-listing-id) u1)
)
