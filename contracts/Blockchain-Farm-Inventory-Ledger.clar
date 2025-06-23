(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-inventory (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-oracle (err u106))

(define-data-var next-crop-id uint u1)
(define-data-var next-storage-id uint u1)
(define-data-var next-sale-id uint u1)

(define-map authorized-oracles principal bool)
(define-map farmers principal bool)

(define-map crops
  uint
  {
    farmer: principal,
    crop-type: (string-ascii 50),
    quantity: uint,
    harvest-date: uint,
    quality-grade: (string-ascii 10),
    location: (string-ascii 100),
    verified: bool,
    oracle-verifier: (optional principal)
  }
)

(define-map storage-records
  uint
  {
    crop-id: uint,
    storage-facility: (string-ascii 100),
    storage-date: uint,
    temperature: int,
    humidity: uint,
    condition: (string-ascii 50),
    verified: bool,
    oracle-verifier: (optional principal)
  }
)

(define-map sales-records
  uint
  {
    crop-id: uint,
    buyer: principal,
    seller: principal,
    quantity-sold: uint,
    price-per-unit: uint,
    sale-date: uint,
    delivery-status: (string-ascii 20),
    verified: bool
  }
)

(define-map farmer-inventory
  { farmer: principal, crop-type: (string-ascii 50) }
  { total-quantity: uint, available-quantity: uint }
)

(define-read-only (get-crop (crop-id uint))
  (map-get? crops crop-id)
)

(define-read-only (get-storage-record (storage-id uint))
  (map-get? storage-records storage-id)
)

(define-read-only (get-sale-record (sale-id uint))
  (map-get? sales-records sale-id)
)

(define-read-only (get-farmer-inventory (farmer principal) (crop-type (string-ascii 50)))
  (default-to 
    { total-quantity: u0, available-quantity: u0 }
    (map-get? farmer-inventory { farmer: farmer, crop-type: crop-type })
  )
)

(define-read-only (is-authorized-oracle (oracle principal))
  (default-to false (map-get? authorized-oracles oracle))
)

(define-read-only (is-registered-farmer (farmer principal))
  (default-to false (map-get? farmers farmer))
)

(define-public (add-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-oracles oracle true))
  )
)

(define-public (remove-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-delete authorized-oracles oracle))
  )
)

(define-public (register-farmer)
  (ok (map-set farmers tx-sender true))
)

(define-public (add-crop 
  (crop-type (string-ascii 50))
  (quantity uint)
  (harvest-date uint)
  (quality-grade (string-ascii 10))
  (location (string-ascii 100))
)
  (let
    (
      (crop-id (var-get next-crop-id))
      (farmer tx-sender)
    )
    (asserts! (is-registered-farmer farmer) err-unauthorized)
    (asserts! (> quantity u0) err-invalid-amount)
    
    (map-set crops crop-id {
      farmer: farmer,
      crop-type: crop-type,
      quantity: quantity,
      harvest-date: harvest-date,
      quality-grade: quality-grade,
      location: location,
      verified: false,
      oracle-verifier: none
    })
    
    (let
      (
        (current-inventory (get-farmer-inventory farmer crop-type))
        (new-total (+ (get total-quantity current-inventory) quantity))
        (new-available (+ (get available-quantity current-inventory) quantity))
      )
      (map-set farmer-inventory 
        { farmer: farmer, crop-type: crop-type }
        { total-quantity: new-total, available-quantity: new-available }
      )
    )
    
    (var-set next-crop-id (+ crop-id u1))
    (ok crop-id)
  )
)

(define-public (verify-crop (crop-id uint))
  (let
    (
      (crop-data (unwrap! (map-get? crops crop-id) err-not-found))
      (oracle tx-sender)
    )
    (asserts! (is-authorized-oracle oracle) err-unauthorized)
    
    (map-set crops crop-id (merge crop-data {
      verified: true,
      oracle-verifier: (some oracle)
    }))
    
    (ok true)
  )
)

(define-public (add-storage-record
  (crop-id uint)
  (storage-facility (string-ascii 100))
  (temperature int)
  (humidity uint)
  (condition (string-ascii 50))
)
  (let
    (
      (storage-id (var-get next-storage-id))
      (crop-data (unwrap! (map-get? crops crop-id) err-not-found))
    )
    (asserts! (is-eq (get farmer crop-data) tx-sender) err-unauthorized)
    
    (map-set storage-records storage-id {
      crop-id: crop-id,
      storage-facility: storage-facility,
      storage-date: stacks-block-height,
      temperature: temperature,
      humidity: humidity,
      condition: condition,
      verified: false,
      oracle-verifier: none
    })
    
    (var-set next-storage-id (+ storage-id u1))
    (ok storage-id)
  )
)

(define-public (verify-storage (storage-id uint))
  (let
    (
      (storage-data (unwrap! (map-get? storage-records storage-id) err-not-found))
      (oracle tx-sender)
    )
    (asserts! (is-authorized-oracle oracle) err-unauthorized)
    
    (map-set storage-records storage-id (merge storage-data {
      verified: true,
      oracle-verifier: (some oracle)
    }))
    
    (ok true)
  )
)

(define-public (create-sale
  (crop-id uint)
  (buyer principal)
  (quantity-sold uint)
  (price-per-unit uint)
)
  (let
    (
      (sale-id (var-get next-sale-id))
      (crop-data (unwrap! (map-get? crops crop-id) err-not-found))
      (seller tx-sender)
      (crop-type (get crop-type crop-data))
      (current-inventory (get-farmer-inventory seller crop-type))
    )
    (asserts! (is-eq (get farmer crop-data) seller) err-unauthorized)
    (asserts! (>= (get available-quantity current-inventory) quantity-sold) err-insufficient-inventory)
    (asserts! (> quantity-sold u0) err-invalid-amount)
    
    (map-set sales-records sale-id {
      crop-id: crop-id,
      buyer: buyer,
      seller: seller,
      quantity-sold: quantity-sold,
      price-per-unit: price-per-unit,
      sale-date: stacks-block-height,
      delivery-status: "pending",
      verified: false
    })
    
    (map-set farmer-inventory 
      { farmer: seller, crop-type: crop-type }
      { 
        total-quantity: (get total-quantity current-inventory),
        available-quantity: (- (get available-quantity current-inventory) quantity-sold)
      }
    )
    
    (var-set next-sale-id (+ sale-id u1))
    (ok sale-id)
  )
)

(define-public (update-delivery-status (sale-id uint) (status (string-ascii 20)))
  (let
    (
      (sale-data (unwrap! (map-get? sales-records sale-id) err-not-found))
    )
    (asserts! (or (is-eq tx-sender (get seller sale-data)) (is-eq tx-sender (get buyer sale-data))) err-unauthorized)
    
    (map-set sales-records sale-id (merge sale-data {
      delivery-status: status
    }))
    
    (ok true)
  )
)

(define-public (verify-sale (sale-id uint))
  (let
    (
      (sale-data (unwrap! (map-get? sales-records sale-id) err-not-found))
    )
    (asserts! (is-authorized-oracle tx-sender) err-unauthorized)
    
    (map-set sales-records sale-id (merge sale-data {
      verified: true
    }))
    
    (ok true)
  )
)

(define-read-only (get-total-crops)
  (- (var-get next-crop-id) u1)
)

(define-read-only (get-total-storage-records)
  (- (var-get next-storage-id) u1)
)

(define-read-only (get-total-sales)
  (- (var-get next-sale-id) u1)
)
