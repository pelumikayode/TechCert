;; TechCert - Technical certification achievement and expertise rewards platform
(define-data-var certification-authority principal tx-sender)
(define-data-var total-expertise-points uint u0)
(define-data-var expertise-bonus-factor uint u45) ;; bonus factor per certification level
(define-data-var last-expertise-review uint u0)

(define-map professional-certifications principal uint)
(define-map technology-domains principal (string-utf8 64))
(define-map accredited-domains (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-authority (err u2000))
(define-constant err-authority-already-established (err u2001))
(define-constant err-invalid-expertise-points (err u2002))
(define-constant err-no-expertise-bonuses (err u2003))
(define-constant err-no-certifications (err u2004))
(define-constant err-invalid-technology-domain (err u2005))
(define-constant err-domain-not-accredited (err u2006))

;; Verify authority authorization
(define-private (is-certification-authority (caller principal))
  (begin
    (asserts! (is-eq caller (var-get certification-authority)) err-unauthorized-authority)
    (ok true)))

;; Initialize technical certification system
(define-public (establish-certification-system (authority principal))
  (begin
    (asserts! (is-none (map-get? professional-certifications authority)) err-authority-already-established)
    (var-set certification-authority authority)
    (ok "TechCert technical certification system established")))

;; Accredit technology domain for certification
(define-public (accredit-technology-domain (domain (string-utf8 64)))
  (begin
    (try! (is-certification-authority tx-sender))
    (asserts! (> (len domain) u0) err-invalid-technology-domain)
    (map-set accredited-domains domain true)
    (ok "Technology domain accredited for certification")))

;; Record technical certification achievement
(define-public (record-certification-achievement (expertise-points uint) (technology-domain (string-utf8 64)))
  (begin
    (asserts! (> expertise-points u0) err-invalid-expertise-points)
    (asserts! (default-to false (map-get? accredited-domains technology-domain)) err-domain-not-accredited)
    
    (let ((current-certifications (default-to u0 (map-get? professional-certifications tx-sender))))
      (map-set professional-certifications tx-sender (+ current-certifications expertise-points))
      (map-set technology-domains tx-sender technology-domain)
      (var-set total-expertise-points (+ (var-get total-expertise-points) expertise-points))
      (ok (+ current-certifications expertise-points)))))

;; Review technical expertise bonuses
(define-public (review-expertise-bonuses)
  (begin
    (try! (is-certification-authority tx-sender))
    (let ((current-review (+ (var-get last-expertise-review) u1))
          (total-points (var-get total-expertise-points)))
      (asserts! (> total-points (var-get last-expertise-review)) err-no-expertise-bonuses)
      
      (let ((expertise-bonus-pool (* (var-get expertise-bonus-factor) total-points)))
        (var-set last-expertise-review current-review)
        (ok expertise-bonus-pool)))))

;; Complete professional certification and claim rewards
(define-public (complete-professional-certification)
  (begin
    (let ((professional-points (default-to u0 (map-get? professional-certifications tx-sender))))
      (asserts! (> professional-points u0) err-no-certifications)
      
      (let ((total-points (var-get total-expertise-points))
            (base-expertise-rewards (* (var-get expertise-bonus-factor) professional-points))
            (certification-ratio (/ (* professional-points u100000) total-points)))
        
        (let ((final-expertise-rewards (/ (* certification-ratio base-expertise-rewards) u100000)))
          (map-delete professional-certifications tx-sender)
          (map-delete technology-domains tx-sender)
          (var-set total-expertise-points (- (var-get total-expertise-points) professional-points))
          (ok (+ professional-points final-expertise-rewards)))))))

;; Read-only functions
(define-read-only (get-professional-certifications (professional principal))
  (default-to u0 (map-get? professional-certifications professional)))

(define-read-only (get-technology-domain (professional principal))
  (map-get? technology-domains professional))

(define-read-only (get-total-expertise-points)
  (var-get total-expertise-points))

(define-read-only (is-domain-accredited (domain (string-utf8 64)))
  (default-to false (map-get? accredited-domains domain)))