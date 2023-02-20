from .utils import ManticoreEVM


# Not used
def resolve_constraint(m: "ManticoreEVM", c_str: str):
    # Assume like this: address(Killme).balance == 0
    var, op, value = c_str.split(" ")
    value = int(value)
    if op == "==":
        m.constrain(var == value)
    elif op == ">=":
        m.constrain(var >= value)
    elif op == "<=":
        m.constrain(var <= value)
    elif op == "!=":
        m.constrain(var != value)
    elif op == ">":
        m.constrain(var > value)
    elif op == "<":
        m.constrain(var < value)
    raise ValueError(f"Unknown op: {op}")
