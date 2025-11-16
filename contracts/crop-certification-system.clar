(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-unauthorized (err u301))
(define-constant err-not-found (err u302))
(define-constant err-already-certified (err u303))
(define-constant err-insufficient-requirements (err u304))

(define-data-var next-certificate-id uint u1)
(define-data-var next-award-id uint u1)

(define-map certification-types
  (string-ascii 30)
  {
    name: (string-ascii 50),
    requirements: (string-ascii 200),
    points-value: uint,
    active: bool
  }
)

(define-map farmer-certificates
  uint
  {
    farmer: principal,
    certificate-type: (string-ascii 30),
    issued-date: uint,
    issuer: principal,
    expires-at: uint,
    metadata: (string-ascii 100)
  }
)

(define-map farmer-awards
  uint
  {
    farmer: principal,
    award-type: (string-ascii 30),
    earned-date: uint,
    points-earned: uint
  }
)

(define-map farmer-reputation
  principal
  {
    total-points: uint,
    certificates-count: uint,
    awards-count: uint,
    reputation-level: (string-ascii 20)
  }
)

(define-public (create-certification-type
  (type-key (string-ascii 30))
  (name (string-ascii 50))
  (requirements (string-ascii 200))
  (points-value uint)
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set certification-types type-key {
      name: name,
      requirements: requirements,
      points-value: points-value,
      active: true
    })
    (ok true)
  )
)

(define-public (issue-certificate
  (farmer principal)
  (certificate-type (string-ascii 30))
  (expires-at uint)
  (metadata (string-ascii 100))
)
  (let
    (
      (cert-id (var-get next-certificate-id))
      (cert-info (unwrap! (map-get? certification-types certificate-type) err-not-found))
    )
    (asserts! (contract-call? .Blockchain-Farm-Inventory-Ledger is-authorized-oracle tx-sender) err-unauthorized)
    
    (map-set farmer-certificates cert-id {
      farmer: farmer,
      certificate-type: certificate-type,
      issued-date: stacks-block-height,
      issuer: tx-sender,
      expires-at: expires-at,
      metadata: metadata
    })
    
    (update-farmer-reputation farmer (get points-value cert-info) u1 u0)
    (var-set next-certificate-id (+ cert-id u1))
    (ok cert-id)
  )
)

(define-public (grant-award
  (farmer principal)
  (award-type (string-ascii 30))
  (points-earned uint)
)
  (let
    (
      (award-id (var-get next-award-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    
    (map-set farmer-awards award-id {
      farmer: farmer,
      award-type: award-type,
      earned-date: stacks-block-height,
      points-earned: points-earned
    })
    
    (update-farmer-reputation farmer points-earned u0 u1)
    (var-set next-award-id (+ award-id u1))
    (ok award-id)
  )
)

(define-private (update-farmer-reputation
  (farmer principal)
  (points-to-add uint)
  (certs-to-add uint)
  (awards-to-add uint)
)
  (let
    (
      (current-rep (default-to 
        { total-points: u0, certificates-count: u0, awards-count: u0, reputation-level: "newcomer" }
        (map-get? farmer-reputation farmer)
      ))
      (new-points (+ (get total-points current-rep) points-to-add))
      (new-certs (+ (get certificates-count current-rep) certs-to-add))
      (new-awards (+ (get awards-count current-rep) awards-to-add))
      (new-level (calculate-reputation-level new-points))
    )
    (map-set farmer-reputation farmer {
      total-points: new-points,
      certificates-count: new-certs,
      awards-count: new-awards,
      reputation-level: new-level
    })
  )
)

(define-private (calculate-reputation-level (total-points uint))
  (if (>= total-points u1000)
    "master-farmer"
    (if (>= total-points u500)
      "expert-farmer"
      (if (>= total-points u200)
        "skilled-farmer"
        (if (>= total-points u50)
          "certified-farmer"
          "newcomer"
        )
      )
    )
  )
)

(define-read-only (get-certificate (cert-id uint))
  (map-get? farmer-certificates cert-id)
)

(define-read-only (get-award (award-id uint))
  (map-get? farmer-awards award-id)
)

(define-read-only (get-farmer-reputation (farmer principal))
  (default-to 
    { total-points: u0, certificates-count: u0, awards-count: u0, reputation-level: "newcomer" }
    (map-get? farmer-reputation farmer)
  )
)

(define-read-only (get-certification-type (type-key (string-ascii 30)))
  (map-get? certification-types type-key)
)

(define-read-only (get-total-certificates)
  (- (var-get next-certificate-id) u1)
)

(define-read-only (get-total-awards)
  (- (var-get next-award-id) u1)
)
