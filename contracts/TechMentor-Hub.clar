;; TechMentor Hub - Mentorship matching and technical skill validation platform
;; Mentors earn tokens through verified teaching and mentee achievement tracking

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant ERR_ALREADY_CONNECTED (err u104))
(define-constant ERR_ALREADY_ASSESSED (err u105))
(define-constant ERR_SELF_ASSESSMENT (err u106))
(define-constant ERR_EMPTY_STRING (err u107))
(define-constant ERR_INVALID_PROFICIENCY (err u108))
(define-constant ERR_INVALID_SESSION_ID (err u109))
(define-constant ERR_EMPTY_HASH (err u110))

;; Constants
(define-constant MAX_PROFICIENCY u5)
(define-constant ENGAGEMENT_REWARD u10)
(define-constant MILESTONE_REWARD u25)
(define-constant MASTERY_REWARD u50)

;; Data maps
(define-map mentors
  { mentor-id: principal }
  { name: (string-ascii 50), expertise: (string-ascii 20), reputation: uint, tokens: uint, active: bool }
)

(define-map mentoring-sessions
  { session-id: uint }
  { 
    mentor: principal, 
    mentee: principal,
    topic: (string-ascii 500), 
    session-hash: (buff 32),
    timestamp: uint, 
    completed: bool,
    review-count: uint,
    progress-count: uint,
    proficiency-level: uint,
    assessment-count: uint
  }
)

(define-map session-reviews
  { session-id: uint, reviewer: principal }
  { reviewed: bool }
)

(define-map progress-tracking
  { session-id: uint, tracker: principal }
  { progress-level: uint, track-date: uint }
)

(define-map proficiency-assessments
  { session-id: uint, assessor: principal }
  { proficiency: uint }
)

;; Variables
(define-data-var next-session-id uint u1)
(define-data-var action-counter uint u0)

;; Helper functions
(define-private (is-valid-session-id (session-id uint))
  (< session-id (var-get next-session-id))
)

;; Mentor functions
(define-public (register-mentor (name (string-ascii 50)) (expertise (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (> (len name) u0) ERR_EMPTY_STRING)
    (asserts! (or (is-eq expertise "blockchain") (is-eq expertise "backend") (is-eq expertise "frontend")) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? mentors {mentor-id: caller})) ERR_ALREADY_EXISTS)
    (ok (map-set mentors 
      {mentor-id: caller} 
      {name: name, expertise: expertise, reputation: u0, tokens: u100, active: false}))
  )
)

(define-public (update-mentor (name (string-ascii 50)) (expertise (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (> (len name) u0) ERR_EMPTY_STRING)
    (asserts! (or (is-eq expertise "blockchain") (is-eq expertise "backend") (is-eq expertise "frontend")) ERR_INVALID_INPUT)
    (asserts! (is-some (map-get? mentors {mentor-id: caller})) ERR_NOT_FOUND)
    (ok (map-set mentors 
      {mentor-id: caller} 
      (merge (unwrap! (map-get? mentors {mentor-id: caller}) ERR_NOT_FOUND)
             {name: name, expertise: expertise})))
  )
)

;; Session functions
(define-public (create-session (mentee principal) (topic (string-ascii 500)) (session-hash (buff 32)))
  (let ((caller tx-sender)
        (session-id (var-get next-session-id)))
    (asserts! (> (len topic) u0) ERR_EMPTY_STRING)
    (asserts! (> (len session-hash) u0) ERR_EMPTY_HASH)
    (asserts! (is-some (map-get? mentors {mentor-id: caller})) ERR_NOT_FOUND)
    (var-set action-counter (+ (var-get action-counter) u1))
    
    (map-set mentoring-sessions 
      {session-id: session-id} 
      { 
        mentor: caller, 
        mentee: mentee,
        topic: topic, 
        session-hash: session-hash,
        timestamp: (var-get action-counter), 
        completed: false,
        review-count: u0,
        progress-count: u0,
        proficiency-level: u0,
        assessment-count: u0
      })
    (var-set next-session-id (+ session-id u1))
    (ok session-id)
  )
)

(define-public (review-session (session-id uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-session-id session-id) ERR_INVALID_SESSION_ID)
    (asserts! (is-some (map-get? mentors {mentor-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? mentoring-sessions {session-id: session-id})) ERR_NOT_FOUND)
    
    (let ((session (unwrap! (map-get? mentoring-sessions {session-id: session-id}) ERR_NOT_FOUND)))
      (asserts! (not (is-eq caller (get mentor session))) ERR_SELF_ASSESSMENT)
      (asserts! (is-none (map-get? session-reviews {session-id: session-id, reviewer: caller})) ERR_ALREADY_CONNECTED)
      
      (map-set session-reviews 
        {session-id: session-id, reviewer: caller} 
        {reviewed: true})
      
      (let ((new-review-count (+ (get review-count session) u1))
            (session-mentor (unwrap! (map-get? mentors {mentor-id: (get mentor session)}) ERR_NOT_FOUND))
            (reviewer-mentor (unwrap! (map-get? mentors {mentor-id: caller}) ERR_NOT_FOUND)))
        
        (map-set mentoring-sessions 
          {session-id: session-id} 
          (merge session {
            review-count: new-review-count,
            completed: (>= new-review-count u3)
          }))
        
        (map-set mentors 
          {mentor-id: caller} 
          (merge reviewer-mentor {
            tokens: (+ (get tokens reviewer-mentor) u5),
            reputation: (+ (get reputation reviewer-mentor) u1)
          }))
        
        (if (and (>= new-review-count u3) (not (get completed session)))
          (map-set mentors 
            {mentor-id: (get mentor session)} 
            (merge session-mentor {
              tokens: (+ (get tokens session-mentor) MASTERY_REWARD),
              reputation: (+ (get reputation session-mentor) u10),
              active: true
            }))
          true)
        
        (ok new-review-count)
      )
    )
  )
)

(define-public (track-progress (session-id uint) (progress-level uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-session-id session-id) ERR_INVALID_SESSION_ID)
    (asserts! (> progress-level u0) ERR_INVALID_INPUT)
    (asserts! (is-some (map-get? mentors {mentor-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? mentoring-sessions {session-id: session-id})) ERR_NOT_FOUND)
    
    (let ((session (unwrap! (map-get? mentoring-sessions {session-id: session-id}) ERR_NOT_FOUND)))
      (asserts! (get completed session) ERR_UNAUTHORIZED)
      
      (map-set progress-tracking 
        {session-id: session-id, tracker: caller} 
        {progress-level: progress-level, track-date: (var-get action-counter)})
      
      (let ((new-progress-count (+ (get progress-count session) progress-level))
            (session-mentor (unwrap! (map-get? mentors {mentor-id: (get mentor session)}) ERR_NOT_FOUND)))
        
        (map-set mentoring-sessions 
          {session-id: session-id} 
          (merge session {progress-count: new-progress-count}))
        
        (map-set mentors 
          {mentor-id: (get mentor session)} 
          (merge session-mentor {
            tokens: (+ (get tokens session-mentor) (* ENGAGEMENT_REWARD progress-level))
          }))
        
        (ok new-progress-count)
      )
    )
  )
)

(define-public (assess-proficiency (session-id uint) (proficiency uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-session-id session-id) ERR_INVALID_SESSION_ID)
    (asserts! (and (>= proficiency u1) (<= proficiency MAX_PROFICIENCY)) ERR_INVALID_PROFICIENCY)
    (asserts! (is-some (map-get? mentors {mentor-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? mentoring-sessions {session-id: session-id})) ERR_NOT_FOUND)
    
    (let ((session (unwrap! (map-get? mentoring-sessions {session-id: session-id}) ERR_NOT_FOUND)))
      (asserts! (not (is-eq caller (get mentor session))) ERR_SELF_ASSESSMENT)
      (asserts! (is-none (map-get? proficiency-assessments {session-id: session-id, assessor: caller})) ERR_ALREADY_ASSESSED)
      
      (map-set proficiency-assessments 
        {session-id: session-id, assessor: caller} 
        {proficiency: proficiency})
      
      (let ((current-total-proficiency (* (get proficiency-level session) (get assessment-count session)))
            (new-assessment-count (+ (get assessment-count session) u1))
            (new-total-proficiency (+ current-total-proficiency proficiency))
            (new-average-proficiency (/ new-total-proficiency new-assessment-count))
            (session-mentor (unwrap! (map-get? mentors {mentor-id: (get mentor session)}) ERR_NOT_FOUND))
            (assessor-mentor (unwrap! (map-get? mentors {mentor-id: caller}) ERR_NOT_FOUND)))
        
        (map-set mentoring-sessions 
          {session-id: session-id} 
          (merge session {
            proficiency-level: new-average-proficiency,
            assessment-count: new-assessment-count
          }))
        
        (map-set mentors 
          {mentor-id: caller} 
          (merge assessor-mentor {
            tokens: (+ (get tokens assessor-mentor) u2),
            reputation: (+ (get reputation assessor-mentor) u1)
          }))
        
        (if (>= proficiency u4)
          (map-set mentors 
            {mentor-id: (get mentor session)} 
            (merge session-mentor {
              tokens: (+ (get tokens session-mentor) MILESTONE_REWARD),
              reputation: (+ (get reputation session-mentor) u5)
            }))
          true)
        
        (ok new-average-proficiency)
      )
    )
  )
)

;; Read-only functions
(define-read-only (get-mentor-profile (mentor-id principal))
  (map-get? mentors {mentor-id: mentor-id})
)

(define-read-only (get-session (session-id uint))
  (map-get? mentoring-sessions {session-id: session-id})
)

(define-read-only (get-session-review (session-id uint) (reviewer principal))
  (map-get? session-reviews {session-id: session-id, reviewer: reviewer})
)

(define-read-only (get-progress-tracking (session-id uint) (tracker principal))
  (map-get? progress-tracking {session-id: session-id, tracker: tracker})
)

(define-read-only (get-proficiency-assessment (session-id uint) (assessor principal))
  (map-get? proficiency-assessments {session-id: session-id, assessor: assessor})
)

(define-read-only (get-total-sessions)
  (- (var-get next-session-id) u1)
)