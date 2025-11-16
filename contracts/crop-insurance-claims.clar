(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-unauthorized (err u401))
(define-constant err-not-found (err u402))
(define-constant err-invalid-amount (err u403))
(define-constant err-claim-closed (err u404))
(define-constant err-already-processed (err u405))

(define-data-var next-claim-id uint u1)

(define-map insurance-claims
  uint
  {
    farmer: principal,
    claim-type: (string-ascii 30),
    reference-id: uint,
    loss-amount: uint,
    description: (string-ascii 200),
    filed-date: uint,
    status: (string-ascii 20),
    oracle-verified: bool,
    oracle-verifier: (optional principal),
    resolution-date: (optional uint)
  }
)

(define-map farmer-claim-stats
  principal
  {
    total-claims: uint,
    approved-claims: uint,
    rejected-claims: uint,
    pending-claims: uint,
    total-claimed-amount: uint
  }
)

(define-public (file-claim
  (claim-type (string-ascii 30))
  (reference-id uint)
  (loss-amount uint)
  (description (string-ascii 200))
)
  (let
    (
      (claim-id (var-get next-claim-id))
      (farmer tx-sender)
    )
    (asserts! (> loss-amount u0) err-invalid-amount)
    
    (map-set insurance-claims claim-id {
      farmer: farmer,
      claim-type: claim-type,
      reference-id: reference-id,
      loss-amount: loss-amount,
      description: description,
      filed-date: stacks-block-height,
      status: "pending",
      oracle-verified: false,
      oracle-verifier: none,
      resolution-date: none
    })
    
    (update-claim-stats farmer loss-amount u1 u0 u0 (to-int u1))
    (var-set next-claim-id (+ claim-id u1))
    (ok claim-id)
  )
)

(define-public (verify-claim (claim-id uint) (approved bool))
  (let
    (
      (claim (unwrap! (map-get? insurance-claims claim-id) err-not-found))
      (oracle tx-sender)
    )
    (asserts! (contract-call? .Blockchain-Farm-Inventory-Ledger is-authorized-oracle oracle) err-unauthorized)
    (asserts! (is-eq (get status claim) "pending") err-claim-closed)
    
    (map-set insurance-claims claim-id (merge claim {
      status: (if approved "approved" "rejected"),
      oracle-verified: true,
      oracle-verifier: (some oracle),
      resolution-date: (some stacks-block-height)
    }))
    
    (if approved
      (update-claim-stats (get farmer claim) u0 u0 u1 u0 (to-int u1))
      (update-claim-stats (get farmer claim) u0 u0 u0 u1 (- (to-int u1)))
    )
    (ok true)
  )
)

(define-private (update-claim-stats
  (farmer principal)
  (claimed-amount uint)
  (total-delta uint)
  (approved-delta uint)
  (rejected-delta uint)
  (pending-change int)
)
  (let
    (
      (current-stats (default-to 
        { total-claims: u0, approved-claims: u0, rejected-claims: u0, pending-claims: u0, total-claimed-amount: u0 }
        (map-get? farmer-claim-stats farmer)
      ))
    )
    (map-set farmer-claim-stats farmer {
      total-claims: (+ (get total-claims current-stats) total-delta),
      approved-claims: (+ (get approved-claims current-stats) approved-delta),
      rejected-claims: (+ (get rejected-claims current-stats) rejected-delta),
      pending-claims: (if (< pending-change 0)
        (- (get pending-claims current-stats) u1)
        (+ (get pending-claims current-stats) (to-uint pending-change))
      ),
      total-claimed-amount: (+ (get total-claimed-amount current-stats) claimed-amount)
    })
  )
)

(define-read-only (get-claim (claim-id uint))
  (map-get? insurance-claims claim-id)
)

(define-read-only (get-farmer-claim-stats (farmer principal))
  (default-to
    { total-claims: u0, approved-claims: u0, rejected-claims: u0, pending-claims: u0, total-claimed-amount: u0 }
    (map-get? farmer-claim-stats farmer)
  )
)

(define-read-only (get-total-claims)
  (- (var-get next-claim-id) u1)
)