import re
from typing import List, Optional

ether = 10**18
gwei = 10**10
max_uint256 = 2**256 - 1

ctrt_name_regex = re.compile(r"\ncontract (\w+)\s+{")


def decimal_to_n_base(decimal: int, base: int) -> List[int]:
    result = []

    while decimal > 0:
        decimal, remainder = divmod(decimal, base)
        result.append(remainder)

    result.reverse()
    return result


def parse_smt_output(key: str, lines: List[str]) -> Optional[str]:
    result = None
    for idx, l in enumerate(lines):
        if key in l:
            result = lines[idx+1].strip().removesuffix(")").replace("#", "0")
            break
    return result

class CompilerError(BaseException):
    """An error happened during code compilation."""

    pass


class CornerCase(BaseException):
    """A corner case has been reached."""

    pass


class FrozenObject(RuntimeError):
    """Don't add item in a freeze graph."""

    pass
