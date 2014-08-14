(export export-pipeline
        dynamic-pipeline
        dynamic-alpha-pipeline)

(define renderable-table (make-hash-table))

(define-external (dynamicRender (c-pointer renderable)) void
  ((hash-table-ref renderable-table renderable) renderable))

(define-external (dynamicPreRender (c-pointer renderable)) void
  #f)

(define-external (dynamicPostRender) void
  #f)

(define dynamic-pipeline (scene:add-pipeline #$dynamicPreRender
                                             #$dynamicRender
                                             #$dynamicPostRender
                                             #f))

;; TODO: make useful:
(define dynamic-alpha-pipeline (scene:add-pipeline #$dynamicPreRender
                                                   #$dynamicRender
                                                   #$dynamicPostRender
                                                   #t))

(define-syntax define-pipeline
  (ir-macro-transformer
   (lambda (exp i c)
     (let* ((name (strip-syntax (cadr exp)))
            (pipeline-name (symbol-append name '-render-pipeline))
            (fast-draw-funs (symbol-append name '-fast-render-functions))
            (draw-fun (symbol-append 'render- name))
            (renderable-maker (symbol-append 'make- name '-renderable)))
       `(begin
          (glls:define-pipeline ,@(cdr exp))
          ,(if (feature? compiling:)
               `(define ,pipeline-name
                  (let-values (((_ __ ___ begin render end) (,fast-draw-funs)))
                    (list ,name
                          (set-finalizer! (scene:add-pipeline begin render end #f)
                                          scene:delete-pipeline)
                          ,renderable-maker)))
               `(define ,pipeline-name
                  (list ,name
                        dynamic-pipeline
                        ,renderable-maker
                        ,draw-fun))))))))

(define-syntax export-pipeline
  (ir-macro-transformer
   (lambda (expr i c)
     (if (and (not (= (length expr) 2))
            (symbol? (cadr expr)))
         (syntax-error 'export-shader "Expected a pipeline name" expr))
     (let* ((name (strip-syntax (cadr expr)))
            (pipeline (symbol-append name '-render-pipeline)))
       `(begin
          (glls:export-pipeline ,name)
          (export ,pipeline))))))

(export-pipeline mesh-shader)
(export-pipeline color-shader)
(export-pipeline sprite-shader)

(define-pipeline mesh-shader
  ((#:vertex input: ((vertex #:vec3))
             uniform: ((mvp #:mat4)))
   (define (main) #:void
     (set! gl:position (* mvp (vec4 vertex 1.0)))))
  ((#:fragment uniform: ((color #:vec3))
               output: ((frag-color #:vec4)))
   (define (main) #:void
     (set! frag-color (vec4 color 1.0)))))

(define-pipeline color-shader
  ((#:vertex input: ((vertex #:vec3) (color #:vec3))
             uniform: ((mvp #:mat4))
             output: ((c #:vec3)))
   (define (main) #:void
     (set! gl:position (* mvp (vec4 vertex 1.0)))
     (set! c color)))
  ((#:fragment input: ((c #:vec3))
               output: ((frag-color #:vec4)))
   (define (main) #:void
     (set! frag-color (vec4 c 1.0)))))

(define-pipeline sprite-shader
  ((#:vertex input: ((vertex #:vec2) (tex-coord #:vec2))
             uniform: ((mvp #:mat4))
             output: ((tex-c #:vec2)))
   (define (main) #:void
     (set! gl:position (* mvp (vec4 vertex 0.0 1.0)))
     (set! tex-c tex-coord)))
  ((#:fragment input: ((tex-c #:vec2))
               uniform: ((tex #:sampler-2d))
               output: ((frag-color #:vec4)))
   (define (main) #:void
     (set! frag-color (texture tex tex-c)))))
