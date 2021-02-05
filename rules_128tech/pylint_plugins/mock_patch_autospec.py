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

    name = "t128-mock-patch-autospec"
    priority = -1
    msgs = {
        "W1280": (
            "Using `%s` without explicitly setting `autospec` is not recommended.",
            name,
            (
                "All mock patches should use autospec=True to avoid allowing calls "
                "to functions that don't exist in production code. See "
                "https://docs.python.org/3.6/library/unittest.mock.html?#autospeccing "
                "for more details"
            ),
        ),
    }

    def visit_call(self, call: astroid.node_classes.Call) -> None:
        if not isinstance(call.func, astroid.node_classes.Attribute):
            # Not a method call, not applicable
            return

        if call.func.attrname == "dict":
            # patch.dict() does not accept spec-related parameters
            return

        found_patch = False
        expr = call.func
        # Traverse the attribute looking for `patch`. This allows us to include
        # mock.patch(), mock.patch.object(), mock.patch.multiple(), etc.
        while isinstance(expr, astroid.node_classes.Attribute):
            if expr.attrname == "patch":
                found_patch = True

            expr = expr.expr

        if not found_patch or not isinstance(expr, astroid.node_classes.Name):
            return

        _parent_node, lookups = expr.lookup(expr.name)
        for lookup in lookups:
            if (
                isinstance(lookup, astroid.node_classes.ImportFrom)
                and lookup.modname == "unittest"
            ):
                self._check_patch_call(call)
                return

            if isinstance(lookup, astroid.node_classes.Import) and any(
                orig_name == "unittest.mock" for orig_name, _alias in lookup.names
            ):
                self._check_patch_call(call)
                return

            # Pytest-mock fixtures are named `mocker` or `<scope>_mocker`
            if isinstance(
                lookup, astroid.node_classes.AssignName
            ) and lookup.name.endswith("mocker"):
                self._check_patch_call(call)
                return

    def _check_patch_call(self, call: astroid.node_classes.Call) -> None:
        assert isinstance(call.func, astroid.node_classes.Attribute)

        if call.func.attrname == "patch" and call.args and len(call.args) > 1:
            # `new` is the second arg, and is incompatible with autospec
            return
        elif call.func.attrname == "object" and call.args and len(call.args) > 2:
            # `new` is the third arg for patch.object()
            return

        kwargs = {keyword.arg for keyword in (call.keywords or [])}
        # All of these args are incompatible with one another, as
        # long as at least one of them is specified, we are good
        if not kwargs.intersection({"new", "spec", "spec_set", "autospec"}):
            self.add_message(self.name, node=call, args=(call.func.as_string(),))
