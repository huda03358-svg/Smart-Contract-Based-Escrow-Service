(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-already-released (err u106))
(define-constant err-already-refunded (err u107))
(define-constant err-deadline-not-passed (err u108))
(define-constant err-deadline-passed (err u109))

(define-constant status-pending u0)
(define-constant status-released u1)
(define-constant status-refunded u2)
(define-constant status-disputed u3)

(define-data-var escrow-counter uint u0)

(define-map escrows
  uint
  {
    buyer: principal,
    seller: principal,
    arbiter: principal,
    amount: uint,
    status: uint,
    deadline: uint,
    created-at: uint
  }
)

(define-map escrow-disputes
  uint
  {
    disputed-at: uint,
    disputed-by: principal,
    resolution: (optional bool)
  }
)

(define-public (create-escrow (seller principal) (arbiter principal) (amount uint) (deadline uint))
  (let
    (
      (escrow-id (+ (var-get escrow-counter) u1))
      (current-height stacks-block-height)
    )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> deadline current-height) err-deadline-passed)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows escrow-id {
      buyer: tx-sender,
      seller: seller,
      arbiter: arbiter,
      amount: amount,
      status: status-pending,
      deadline: deadline,
      created-at: current-height
    })
    (var-set escrow-counter escrow-id)
    (ok escrow-id)
  )
)

(define-public (release-funds (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq (get status escrow) status-pending) err-invalid-status)
    (asserts! (or (is-eq tx-sender (get buyer escrow)) (is-eq tx-sender (get arbiter escrow))) err-unauthorized)
    (asserts! (<= current-height (get deadline escrow)) err-deadline-passed)
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
    (map-set escrows escrow-id (merge escrow { status: status-released }))
    (ok true)
  )
)

(define-public (refund-funds (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq (get status escrow) status-pending) err-invalid-status)
    (asserts! (or 
      (and (is-eq tx-sender (get seller escrow)) (<= current-height (get deadline escrow)))
      (and (is-eq tx-sender (get buyer escrow)) (> current-height (get deadline escrow)))
      (is-eq tx-sender (get arbiter escrow))
    ) err-unauthorized)
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))
    (map-set escrows escrow-id (merge escrow { status: status-refunded }))
    (ok true)
  )
)

(define-public (raise-dispute (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq (get status escrow) status-pending) err-invalid-status)
    (asserts! (or (is-eq tx-sender (get buyer escrow)) (is-eq tx-sender (get seller escrow))) err-unauthorized)
    (asserts! (<= current-height (get deadline escrow)) err-deadline-passed)
    (map-set escrows escrow-id (merge escrow { status: status-disputed }))
    (map-set escrow-disputes escrow-id {
      disputed-at: current-height,
      disputed-by: tx-sender,
      resolution: none
    })
    (ok true)
  )
)

(define-public (resolve-dispute (escrow-id uint) (release-to-seller bool))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (dispute (unwrap! (map-get? escrow-disputes escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq (get status escrow) status-disputed) err-invalid-status)
    (asserts! (is-eq tx-sender (get arbiter escrow)) err-unauthorized)
    (if release-to-seller
      (begin
        (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
        (map-set escrows escrow-id (merge escrow { status: status-released }))
      )
      (begin
        (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))
        (map-set escrows escrow-id (merge escrow { status: status-refunded }))
      )
    )
    (map-set escrow-disputes escrow-id (merge dispute { resolution: (some release-to-seller) }))
    (ok true)
  )
)

(define-public (extend-deadline (escrow-id uint) (new-deadline uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (asserts! (is-eq (get status escrow) status-pending) err-invalid-status)
    (asserts! (or (is-eq tx-sender (get buyer escrow)) (is-eq tx-sender (get seller escrow))) err-unauthorized)
    (asserts! (> new-deadline (get deadline escrow)) err-invalid-amount)
    (map-set escrows escrow-id (merge escrow { deadline: new-deadline }))
    (ok true)
  )
)

(define-read-only (get-escrow (escrow-id uint))
  (ok (map-get? escrows escrow-id))
)

(define-read-only (get-dispute (escrow-id uint))
  (ok (map-get? escrow-disputes escrow-id))
)

(define-read-only (get-escrow-count)
  (ok (var-get escrow-counter))
)

(define-read-only (get-escrow-status (escrow-id uint))
  (ok (get status (unwrap! (map-get? escrows escrow-id) err-not-found)))
)

(define-read-only (get-escrow-amount (escrow-id uint))
  (ok (get amount (unwrap! (map-get? escrows escrow-id) err-not-found)))
)

(define-read-only (get-escrow-deadline (escrow-id uint))
  (ok (get deadline (unwrap! (map-get? escrows escrow-id) err-not-found)))
)

(define-read-only (is-escrow-expired (escrow-id uint))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (ok (> current-height (get deadline escrow)))
  )
)

(define-read-only (can-release (escrow-id uint) (caller principal))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
    )
    (ok (and 
      (is-eq (get status escrow) status-pending)
      (or (is-eq caller (get buyer escrow)) (is-eq caller (get arbiter escrow)))
    ))
  )
)

(define-read-only (can-refund (escrow-id uint) (caller principal))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (ok (and 
      (is-eq (get status escrow) status-pending)
      (or 
        (and (is-eq caller (get seller escrow)) (<= current-height (get deadline escrow)))
        (and (is-eq caller (get buyer escrow)) (> current-height (get deadline escrow)))
        (is-eq caller (get arbiter escrow))
      )
    ))
  )
)

(define-read-only (can-dispute (escrow-id uint) (caller principal))
  (let
    (
      (escrow (unwrap! (map-get? escrows escrow-id) err-not-found))
      (current-height stacks-block-height)
    )
    (ok (and 
      (is-eq (get status escrow) status-pending)
      (or (is-eq caller (get buyer escrow)) (is-eq caller (get seller escrow)))
      (<= current-height (get deadline escrow))
    ))
  )
)
