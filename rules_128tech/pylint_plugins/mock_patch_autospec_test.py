"""Unit tests for the mock_patch_autospec plugin"""

import contextlib

import astroid
import astroid.node_classes
import pytest
from pylint import testutils

from rules_128tech.pylint_plugins import mock_patch_autospec


class TestUniqueReturnChecker(testutils.CheckerTestCase):

    CHECKER_CLASS = mock_patch_autospec.MockPatchAutospecChecker

    @pytest.fixture(
        params=[
            pytest.param(
                """
                {imports}

                class FakeFoo:
                    pass

                @{func_name}{call_args}  #@
                def test():
                    pass
                """,
                id="decorator",
            ),
            pytest.param(
                """
                {imports}

                class FakeFoo:
                    pass

                def test():
                    with {func_name}{call_args}:  #@
                        pass
                """,
                id="context_manager",
            ),
        ]
    )
    def source_template(self, request):
        return request.param

    @pytest.mark.parametrize(
        "imports, func_name",
        [
            pytest.param(
                "import unittest.mock", "unittest.mock.patch", id="fully_qualified"
            ),
            pytest.param(
                "from unittest import mock", "mock.patch", id="partially_qualified"
            ),
        ],
    )
    @pytest.mark.parametrize(
        "call_args, should_flag",
        [
            pytest.param('("foo")', True, id="no_autospec",),
            pytest.param('("foo", FakeFoo())', False, id="new_arg_specified",),
            pytest.param('("foo", new=FakeFoo())', False, id="new_kwarg_specified",),
            pytest.param('("foo", autospec=True)', False, id="autospec_true",),
            pytest.param('("foo", autospec=False)', False, id="autospec_false",),
        ],
    )
    def test_unittest_mock_patch_context_manager(
        self, source_template, call_args, should_flag, imports, func_name,
    ):
        source_code = source_template.format(
            imports=imports, func_name=func_name, call_args=call_args
        )
        decorator_or_with_stmt: astroid.node_classes.NodeNG = astroid.extract_node(source_code)  # type: ignore

        patch_call = next(decorator_or_with_stmt.get_children())

        with contextlib.ExitStack() as stack:
            if should_flag:
                stack.enter_context(
                    self.assertAddsMessages(
                        testutils.Message(
                            msg_id=mock_patch_autospec.MockPatchAutospecChecker.name,
                            node=patch_call,
                            args=(func_name,),
                        ),
                    )
                )
            else:
                stack.enter_context(self.assertNoMessages())

            self.checker.visit_call(patch_call)
