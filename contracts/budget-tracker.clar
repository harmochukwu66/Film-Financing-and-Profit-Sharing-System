;; Budget Tracker Contract
;; Monitors production costs, budget allocation, and expense approval workflows

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-BUDGET-NOT-FOUND (err u301))
(define-constant ERR-EXPENSE-NOT-FOUND (err u302))
(define-constant ERR-INSUFFICIENT-BUDGET (err u303))
(define-constant ERR-INVALID-AMOUNT (err u304))
(define-constant ERR-ALREADY-APPROVED (err u305))

;; Expense categories
(define-constant CATEGORY-PRE-PRODUCTION u1)
(define-constant CATEGORY-CAST u2)
(define-constant CATEGORY-CREW u3)
(define-constant CATEGORY-EQUIPMENT u4)
(define-constant CATEGORY-LOCATIONS u5)
(define-constant CATEGORY-POST-PRODUCTION u6)
(define-constant CATEGORY-MARKETING u7)
(define-constant CATEGORY-DISTRIBUTION u8)

;; Expense status
(define-constant STATUS-PENDING u1)
(define-constant STATUS-APPROVED u2)
(define-constant STATUS-REJECTED u3)
(define-constant STATUS-PAID u4)

;; Data structures
(define-map film-budgets
  { film-id: uint }
  {
    total-budget: uint,
    allocated-budget: uint,
    spent-budget: uint,
    remaining-budget: uint,
    contingency-percentage: uint,
    created-by: principal,
    created-at: uint
  }
)

(define-map budget-categories
  { film-id: uint, category: uint }
  {
    allocated-amount: uint,
    spent-amount: uint,
    remaining-amount: uint
  }
)

(define-map expenses
  { expense-id: uint }
  {
    film-id: uint,
    category: uint,
    amount: uint,
    description: (string-ascii 200),
    vendor: (string-ascii 100),
    requested-by: principal,
    approved-by: (optional principal),
    status: uint,
    created-at: uint,
    approved-at: (optional uint)
  }
)

(define-data-var next-expense-id uint u1)

;; Public functions

;; Initialize budget for a film
(define-public (initialize-budget (film-id uint) (total-budget uint) (contingency-percentage uint))
  (begin
    (asserts! (> total-budget u0) ERR-INVALID-AMOUNT)
    (asserts! (<= contingency-percentage u20) ERR-INVALID-AMOUNT) ;; Max 20% contingency

    (map-set film-budgets
      { film-id: film-id }
      {
        total-budget: total-budget,
        allocated-budget: u0,
        spent-budget: u0,
        remaining-budget: total-budget,
        contingency-percentage: contingency-percentage,
        created-by: tx-sender,
        created-at: block-height
      }
    )

    (ok true)
  )
)

;; Allocate budget to a category
(define-public (allocate-budget (film-id uint) (category uint) (amount uint))
  (let ((budget (unwrap! (map-get? film-budgets { film-id: film-id }) ERR-BUDGET-NOT-FOUND)))

    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (and (>= category CATEGORY-PRE-PRODUCTION) (<= category CATEGORY-DISTRIBUTION)) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (get allocated-budget budget) amount) (get total-budget budget)) ERR-INSUFFICIENT-BUDGET)

    ;; Update category allocation
    (let ((existing-category (default-to
                               { allocated-amount: u0, spent-amount: u0, remaining-amount: u0 }
                               (map-get? budget-categories { film-id: film-id, category: category }))))

      (map-set budget-categories
        { film-id: film-id, category: category }
        {
          allocated-amount: (+ (get allocated-amount existing-category) amount),
          spent-amount: (get spent-amount existing-category),
          remaining-amount: (+ (get remaining-amount existing-category) amount)
        }
      )
    )

    ;; Update total budget allocation
    (map-set film-budgets
      { film-id: film-id }
      (merge budget {
        allocated-budget: (+ (get allocated-budget budget) amount),
        remaining-budget: (- (get remaining-budget budget) amount)
      })
    )

    (ok true)
  )
)

;; Submit an expense for approval
(define-public (submit-expense
  (film-id uint)
  (category uint)
  (amount uint)
  (description (string-ascii 200))
  (vendor (string-ascii 100)))
  (let ((expense-id (var-get next-expense-id))
        (budget (unwrap! (map-get? film-budgets { film-id: film-id }) ERR-BUDGET-NOT-FOUND))
        (category-budget (unwrap! (map-get? budget-categories { film-id: film-id, category: category }) ERR-BUDGET-NOT-FOUND)))

    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= amount (get remaining-amount category-budget)) ERR-INSUFFICIENT-BUDGET)

    (map-set expenses
      { expense-id: expense-id }
      {
        film-id: film-id,
        category: category,
        amount: amount,
        description: description,
        vendor: vendor,
        requested-by: tx-sender,
        approved-by: none,
        status: STATUS-PENDING,
        created-at: block-height,
        approved-at: none
      }
    )

    (var-set next-expense-id (+ expense-id u1))
    (ok expense-id)
  )
)

;; Approve an expense
(define-public (approve-expense (expense-id uint))
  (let ((expense (unwrap! (map-get? expenses { expense-id: expense-id }) ERR-EXPENSE-NOT-FOUND))
        (budget (unwrap! (map-get? film-budgets { film-id: (get film-id expense) }) ERR-BUDGET-NOT-FOUND))
        (category-budget (unwrap! (map-get? budget-categories { film-id: (get film-id expense), category: (get category expense) }) ERR-BUDGET-NOT-FOUND)))

    (asserts! (is-eq (get status expense) STATUS-PENDING) ERR-ALREADY-APPROVED)
    (asserts! (<= (get amount expense) (get remaining-amount category-budget)) ERR-INSUFFICIENT-BUDGET)

    ;; Update expense status
    (map-set expenses
      { expense-id: expense-id }
      (merge expense {
        approved-by: (some tx-sender),
        status: STATUS-APPROVED,
        approved-at: (some block-height)
      })
    )

    ;; Update category budget
    (map-set budget-categories
      { film-id: (get film-id expense), category: (get category expense) }
      (merge category-budget {
        spent-amount: (+ (get spent-amount category-budget) (get amount expense)),
        remaining-amount: (- (get remaining-amount category-budget) (get amount expense))
      })
    )

    ;; Update total budget
    (map-set film-budgets
      { film-id: (get film-id expense) }
      (merge budget {
        spent-budget: (+ (get spent-budget budget) (get amount expense))
      })
    )

    (ok true)
  )
)

;; Mark expense as paid
(define-public (mark-expense-paid (expense-id uint))
  (let ((expense (unwrap! (map-get? expenses { expense-id: expense-id }) ERR-EXPENSE-NOT-FOUND)))

    (asserts! (is-eq (get status expense) STATUS-APPROVED) ERR-NOT-AUTHORIZED)

    (map-set expenses
      { expense-id: expense-id }
      (merge expense { status: STATUS-PAID })
    )

    (ok true)
  )
)

;; Read-only functions

;; Get film budget
(define-read-only (get-film-budget (film-id uint))
  (map-get? film-budgets { film-id: film-id })
)

;; Get category budget
(define-read-only (get-category-budget (film-id uint) (category uint))
  (map-get? budget-categories { film-id: film-id, category: category })
)

;; Get expense details
(define-read-only (get-expense (expense-id uint))
  (map-get? expenses { expense-id: expense-id })
)

;; Get budget utilization percentage
(define-read-only (get-budget-utilization (film-id uint))
  (match (map-get? film-budgets { film-id: film-id })
    budget (if (> (get total-budget budget) u0)
             (/ (* (get spent-budget budget) u100) (get total-budget budget))
             u0)
    u0
  )
)

;; Check if expense can be approved
(define-read-only (can-approve-expense (expense-id uint))
  (match (map-get? expenses { expense-id: expense-id })
    expense (and
              (is-eq (get status expense) STATUS-PENDING)
              (match (map-get? budget-categories { film-id: (get film-id expense), category: (get category expense) })
                category-budget (<= (get amount expense) (get remaining-amount category-budget))
                false))
    false
  )
)
