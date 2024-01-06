class CompilerError(BaseException):
    """An error happened during the code compilation."""

    pass


class CornerCase(BaseException):
    """A corner case has been reached."""

    pass
