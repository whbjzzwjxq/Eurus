from pyparsing import (Forward, Group, Keyword, Literal, Word, ZeroOrMore,
                       alphas)

# Define the grammar rules
identifier = Word(alphas, alphas + '_')
constant = Literal('true') | Literal('false')
term = constant | identifier
predicate = identifier + '(' + Group(term + ZeroOrMore(',' + term)) + ')'
formula = Forward()
atom = predicate | term
formula << atom + ZeroOrMore(('and' | 'or') + atom)


def parse_zero_order_logic(s: str):
    pass