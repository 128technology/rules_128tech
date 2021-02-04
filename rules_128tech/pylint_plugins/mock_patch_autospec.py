"""
A plugin to detect and disallow the use of mock.patch or mocker.patch without
setting autospec=True.

Based on http://pylint.pycqa.org/en/latest/how_tos/custom_checkers.html#write-a-checker
"""

import astroid
import astroid.node_classes
from pylint.checkers import BaseChecker
from pylint.interfaces import IAstroidChecker


def register(linter):
    linter.register_checker(MockPatchAutospecChecker(linter))


class MockPatchAutospecChecker(BaseChecker):
    """A pylint checker to detect use of mock.patch without autospec=True"""

    __implements__ = IAstroidChecker

    name = "mock-patch-autospec"
    priority = -1
    msgs = {
        "W1280": (
            "Uses mock.patch without autospec=True.",
            name,
            (
                "All mock patches should use autospec=True to avoid allowing calls "
                "to functions that don't exist in production code"
            ),
        ),
    }

    def visit_call(self, call: astroid.node_classes.Call) -> None:
        if not isinstance(call.func, astroid.node_classes.Attribute):
            # Not a method call, not applicable
            return

        if call.func.attrname != "patch":
            # Some other method, not applicable
            return

        if not isinstance(call.func.expr, astroid.node_classes.Name):
            # A method call on a complex expression, literal, or something
            return

        if call.func.expr.name not in ("mock", "mocker"):
            # Call to .patch() on some other object, I guess...
            return

        if call.keywords:
            for keyword in call.keywords:
                if keyword.arg == "autospec":
                    if (
                        isinstance(keyword.value, astroid.node_classes.Const)
                        and keyword.value.value is True
                    ):
                        # They did the right thing!
                        return

                    # They passed a non-True value, probably an error
                    self.add_message(
                        "mock-patch-autospec", node=keyword.value,
                    )

        # We looked at all the kwargs and didn't find autospec=True, uh-oh
        self.add_message("mock-patch-autospec", node=call)
