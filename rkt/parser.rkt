#lang typed/racket

(require json)

;; Define a struct to represent a variable
(struct variable ([name : string] [type : string]))

;; Define a struct to represent an expression
(struct expression ([type : string]))

(struct assign-op-expr expression ([operator : string] [left : expression] [right : expression]))
(struct binary-op-expr expression ([operator : string] [left : expression] [right : expression]))
(struct call-expr expression ([called : expression] [arguments : (Listof expression)] [eth-value : expression]))
(struct literal-expr expression ([value : any]))
(struct type-conv-expr expression ([from-expr : expression] [to-type : string]))
(struct tuple-expr expression ([exprs : (Listof expression)]))
(struct mem-acc-expr expression ([member-name : string] [from-expr : expression]))
(struct unary-expr expression ([operator : string] [right : expression]))
(struct index-access-expr expression ([left : expression] [right : expression]))
(struct identifier-expr expression ([value : string]))

;; Define a struct to represent a function
(struct function ([name : string] [parameters : (Listof variable)] [statements : (Listof expression)]))

;; Define a struct to represent a contract
(struct contract ([name : string] [functions : (Listof function)] [state-variables : (Listof variable)]))

;; Define a struct to represent the Defi
(struct defi ([contracts : (Listof contract)] [attack-goal : string] [project-name : string]))

(define file-name (vector-ref (current-command-line-arguments) 0))

;; Define a helper function to parse an expression
(define (parse-expression expr : string) : expression
  (match expr
    ["assign_op" (expression 'assign-op operator left right)]
    ["binary_op" (expression 'binary-op operator left right)]
    ["call" (expression 'call called arguments value)]
    ["unary" (expression 'unary operator right)]
    ["index_access" (expression 'index-access is-lvalue left right)]
    ["identifier" (expression 'identifier value)]
    ["literal" (expression 'literal value)]
    [_ (error 'parse-expression "Unknown expression type")]))

;; Define a helper function to parse a variable
(define (parse-variable var : any) : variable
  (match var
    [("solidity_function") (variable 'solidity-function)]
    [("function" contract) (variable 'function contract)]
    [("event") (variable 'event)]
    [("modifier" contract) (variable 'modifier contract)]
    [("contract") (variable 'contract)]
    [(name type) (variable name type)]
    [_ (error 'parse-variable "Unknown variable type")]))

;; Define a helper function to parse a function
(define (parse-function func : any) : function
  (match func
    [(name parameters statements) (function name parameters statements)]
    [_ (error 'parse-function "Invalid function format")]))

;; Define a helper function to parse a contract
(define (parse-contract ctrt : any) : contract
  (match ctrt
    [(name functions state-variables) (contract name (map parse-function functions) (map parse-variable state-variables))]
    [_ (error 'parse-contract "Invalid contract format")]))

;; Define a helper function to parse the Defi
(define (parse-defi defi : any) : defi
  (match defi
    [(contracts attack-goal project-name)
     (defi (map parse-contract contracts) attack-goal project-name)]
    [_ (error 'parse-defi "Invalid Defi format")]))

;; Read the JSON input
(define json-input (file->string file-name))

;; Parse the JSON input
(define parsed-json (string->jsexpr json-input))

;; Parse the Defi from the parsed JSON
(define parsed-defi (parse-defi parsed-json))

;; Access the parsed Defi data
(define parsed-contracts (defi-contracts parsed-defi))
(define parsed-attack-goal (defi-attack-goal parsed-defi))
(define parsed-project-name (defi-project-name parsed-defi))
