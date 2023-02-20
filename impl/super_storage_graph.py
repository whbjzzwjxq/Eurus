from typing import List


class Constraint:

    def __init__(self, v_a: str, expr: str, v_b: str) -> None:
        self.v_a = v_a
        self.expr = expr
        self.v_b = v_b

class SSGNode:

    def __init__(self, constraints: List[Constraint]) -> None:
        self.constraints = constraints

    def variables():
        pass
