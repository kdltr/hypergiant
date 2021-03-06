;;;; math.scm

;;;; Math utilities
;;;; Imported by hypergiant.scm

(import (chicken random))

(export random-normal
        random-float
        clamp
        vclamp
        vclamp!
        v/
        vround
        vceiling
        vtruncate
        vfloor
        next-power-of-two
        ease
        linenear
        smooth-step
        smoother-step)

(define (random-normal mean sd)
  (+ mean (* sd (pseudo-random-real))))

(define (random-float)
  ((if (zero? (pseudo-random-integer 2)) + -)
   (let lp ((n (pseudo-random-real)))
     (if (= n 1.0) (lp (pseudo-random-real)) n))))

(define (clamp x l u)
  (min (max x l) u))

;; TODO vector operations could match gl-math better: optional return arguments that dictate where the result is created
(define (vclamp v l u #!optional non-gc?)
  (make-point (clamp (point-x v) l u)
              (clamp (point-y v) l u)
              (clamp (point-z v) l u)
              non-gc?))

(define (vclamp! v l u)
  (point-x-set! (clamp (point-x v) l u))
  (point-y-set! (clamp (point-y v) l u))
  (point-z-set! (clamp (point-z v) l u)))

(define (v/ v s #!optional result)
  (let ((r (/ s)))
    (v* v r result)))

(define (vround v #!optional non-gc?)
  (make-point (round (point-x v))
              (round (point-y v))
              (round (point-z v))
              non-gc?))

(define (vfloor v #!optional non-gc?)
  (make-point (floor (point-x v))
              (floor (point-y v))
              (floor (point-z v))
              non-gc?))

(define (vceiling v #!optional non-gc?)
  (make-point (ceiling (point-x v))
              (ceiling (point-y v))
              (ceiling (point-z v))
              non-gc?))

(define (vtruncate v #!optional non-gc?)
  (make-point (truncate (point-x v))
              (truncate (point-y v))
              (truncate (point-z v))
              non-gc?))

(define (next-power-of-two n)
  (inexact->exact (expt 2 (ceiling (/ (log n)
                                      (log 2))))))

;;;; Easing functions
;; TODO more: https://github.com/EmmanuelOga/easing/blob/master/lib/easing.lua
;;            http://sol.gfxile.net/interpolation/
(define (ease fun a b time start end)
  (+ a (* (- b a)
          (fun (/ (- time start)
                  (- end start))))))

(define linenear identity)

(define (smooth-step x)
  (* x x
     (- 3 (* 2 x))))

(define (smoother-step x)
  (* x x x
     (+ (* x (- (* x 6)
                15))
        10)))
