;; ------------------------------------------------------------
;; Lottery Smart Contract
;; Description: Players buy tickets with STX. 
;; Admin can close lottery and draw a random winner.
;; ------------------------------------------------------------

(define-constant ERR_ZERO_AMOUNT        (err u100))
(define-constant ERR_NOT_OPEN           (err u101))
(define-constant ERR_ALREADY_CLOSED     (err u102))
(define-constant ERR_NOT_AUTHORIZED     (err u103))
(define-constant ERR_NO_TICKETS         (err u104))
(define-constant ERR_WINNER_NOT_SET     (err u105))
(define-constant ERR_ALREADY_DRAWN      (err u106))
(define-constant ERR_TRANSFER_FAILED    (err u107))

;; ------------------------------------------------------------
;; Global state variables
;; ------------------------------------------------------------
(define-data-var admin principal tx-sender)
(define-data-var lottery-open bool true)
(define-data-var ticket-price uint u2000000) ;; 2 STX per ticket
(define-data-var total-tickets uint u0)
(define-data-var total-pool uint u0)
(define-data-var winner (optional principal) none)
(define-data-var round uint u1)

;; ------------------------------------------------------------
;; Map to store tickets: ticket-number player principal
;; ------------------------------------------------------------
(define-map tickets uint principal)

;; ------------------------------------------------------------
;; Function: Buy lottery ticket
;; ------------------------------------------------------------
(define-public (buy-ticket)
  (begin
    (asserts! (var-get lottery-open) ERR_NOT_OPEN)
    (try! (stx-transfer? (var-get ticket-price) tx-sender (as-contract tx-sender)))
    (var-set total-tickets (+ (var-get total-tickets) u1))
    (var-set total-pool (+ (var-get total-pool) (var-get ticket-price)))
    (map-set tickets (var-get total-tickets) tx-sender)
    (ok (tuple (ticket-no (var-get total-tickets)) (buyer tx-sender)))
  )
)

;; ------------------------------------------------------------
;; Admin: Close the lottery for drawing
;; ------------------------------------------------------------
(define-public (close-lottery)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (var-get lottery-open) ERR_ALREADY_CLOSED)
    (var-set lottery-open false)
    (ok "Lottery closed. Ready to draw winner.")
  )
)

;; ------------------------------------------------------------
;; Admin: Draw winner (pseudo-random based on block height)
;; ------------------------------------------------------------
(define-public (draw-winner)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (var-get winner)) ERR_ALREADY_DRAWN)
    (asserts! (> (var-get total-tickets) u0) ERR_NO_TICKETS)
    (let ((winning-number (+ u1 (mod burn-block-height (var-get total-tickets)))))
      (match (map-get? tickets winning-number)
        player
          (begin
            (var-set winner (some player))
            (ok (tuple (winning-ticket winning-number) (winner player)))
          )
        (err u1)
      )
    )
  )
)

;; ------------------------------------------------------------
;; Admin: Payout winnings to the winner
;; ------------------------------------------------------------
(define-public (payout)
  (match (var-get winner)
    winner-principal
      (match (stx-transfer? (var-get total-pool) (as-contract tx-sender) winner-principal)
        success (begin
            (var-set total-pool u0)
            (ok (tuple (paid-to winner-principal) (amount (var-get total-pool))))
          )
        error ERR_TRANSFER_FAILED
      )
    ERR_WINNER_NOT_SET
  )
)

;; ------------------------------------------------------------
;; Admin: Reset lottery for next round
;; ------------------------------------------------------------
(define-public (reset-lottery)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
    (var-set total-tickets u0)
    (var-set total-pool u0)
    (var-set winner none)
    (var-set round (+ (var-get round) u1))
    (var-set lottery-open true)
    (ok (tuple (new-round (var-get round)) (status "Lottery reopened")))
  )
)

;; ------------------------------------------------------------
;; Read-only: Get ticket owner
;; ------------------------------------------------------------
(define-read-only (get-ticket (num uint))
  (ok (map-get? tickets num))
)

;; ------------------------------------------------------------
;; Read-only: Lottery status
;; ------------------------------------------------------------
(define-read-only (get-status)
  (ok (tuple
        (lottery-open (var-get lottery-open))
        (total-tickets (var-get total-tickets))
        (ticket-price (var-get ticket-price))
        (total-pool (var-get total-pool))
        (winner (var-get winner))
        (round (var-get round))
      ))
)

;; ------------------------------------------------------------
;; Read-only: Get admin
;; ------------------------------------------------------------
(define-read-only (get-admin)
  (ok (var-get admin))
)