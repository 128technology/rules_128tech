"""Unit tests for the mock_patch_autospec plugin"""

import contextlib
from unittest import mock

import astroid
import astroid.node_classes
import pytest
from pylint import testutils

from rules_128tech.pylint_plugins import mock_patch_autospec


_MOCK_PATCH_TEST_CASES = [
    pytest.param('("foo")', True, id="no_autospec",),
    pytest.param('("foo", FakeFoo())', False, id="new_arg_specified",),
    pytest.param('("foo", new=FakeFoo())', False, id="new_kwarg_specified",),
    pytest.param('("foo", spec=FakeFoo)', False, id="spec_kwarg_specified",),
    pytest.param('("foo", spec_set=FakeFoo)', False, id="spec_set_specified",),
    pytest.param('("foo", autospec=True)', False, id="autospec_true",),
    pytest.param('("foo", autospec=False)', False, id="autospec_false",),
]


_MOCK_PATCH_OBJECT_TEST_CASES = [
    pytest.param('(time, "time")', True, id="no_autospec",),
    pytest.param('(time, "time", FakeFoo())', False, id="new_arg_specified",),
    pytest.param('(time, "time", new=FakeFoo())', False, id="new_kwarg_specified",),
    pytest.param('(time, "time", spec=FakeFoo)', False, id="spec_kwarg_specified",),
    pytest.param('(time, "time", spec_set=FakeFoo)', False, id="spec_set_specified",),
    pytest.param('(time, "time", autospec=True)', False, id="autospec_true",),
    pytest.param('(time, "time", autospec=False)', False, id="autospec_false",),
]

_MOCK_PATCH_DICT_TEST_CASES = [
    pytest.param('("os.environ", FOO="bar")', id="kwargs",),
    pytest.param('("os.environ", {"FOO": "bar"})', id="dict",),
]


class TestUnittestMockPatch(testutils.CheckerTestCase):

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
        "call_args, should_flag", _MOCK_PATCH_TEST_CASES,
    )
    def test_mock_patch(
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

    @pytest.mark.parametrize(
        "imports, func_name",
        [
            pytest.param(
                """
                import time
                import unittest.mock
                """,
                "unittest.mock.patch.object",
                id="fully_qualified",
            ),
            pytest.param(
                """
                import time
                from unittest import mock
                """,
                "mock.patch.object",
                id="partially_qualified",
            ),
        ],
    )
    @pytest.mark.parametrize(
        "call_args, should_flag", _MOCK_PATCH_OBJECT_TEST_CASES,
    )
    def test_mock_patch_object(
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

    @pytest.mark.parametrize(
        "imports, func_name",
        [
            pytest.param(
                """
                import os
                import unittest.mock
                """,
                "unittest.mock.patch.dict",
                id="fully_qualified",
            ),
            pytest.param(
                """
                import os
                from unittest import mock
                """,
                "mock.patch.dict",
                id="partially_qualified",
            ),
        ],
    )
    @pytest.mark.parametrize(
        "call_args", _MOCK_PATCH_DICT_TEST_CASES,
    )
    def test_mock_patch_dict(
        self, source_template, call_args, imports, func_name,
    ):
        source_code = source_template.format(
            imports=imports, func_name=func_name, call_args=call_args
        )
        decorator_or_with_stmt: astroid.node_classes.NodeNG = astroid.extract_node(source_code)  # type: ignore

        patch_call = next(decorator_or_with_stmt.get_children())

        with self.assertNoMessages():
            self.checker.visit_call(patch_call)


class TestPytestMockFixture(testutils.CheckerTestCase):

    CHECKER_CLASS = mock_patch_autospec.MockPatchAutospecChecker

    @pytest.fixture(
        params=[
            "mocker",
            "module_mocker",
            "class_mocker",
            "package_mocker",
            "session_mocker",
        ]
    )
    def fixture_name(self, request):
        return request.param

    @pytest.fixture
    def source_template(self, fixture_name):
        return f"""
            def test({fixture_name}):
                {fixture_name}.{{func_name}}{{call_args}}  #@
        """

    @pytest.mark.parametrize("call_args, should_flag", _MOCK_PATCH_TEST_CASES)
    def test_mock_patch(self, source_template, should_flag, call_args, fixture_name):
        func_name = "patch"
        source_code = source_template.format(call_args=call_args, func_name=func_name)
        patch_call = astroid.extract_node(source_code)

        with contextlib.ExitStack() as stack:
            if should_flag:
                stack.enter_context(
                    self.assertAddsMessages(
                        testutils.Message(
                            msg_id=mock_patch_autospec.MockPatchAutospecChecker.name,
                            node=patch_call,
                            args=(f"{fixture_name}.{func_name}",),
                        ),
                    )
                )
            else:
                stack.enter_context(self.assertNoMessages())

            self.checker.visit_call(patch_call)

    @pytest.mark.parametrize("call_args, should_flag", _MOCK_PATCH_OBJECT_TEST_CASES)
    def test_mock_object(self, source_template, call_args, should_flag, fixture_name):
        func_name = "patch.object"
        source_code = source_template.format(call_args=call_args, func_name=func_name)
        patch_call = astroid.extract_node(source_code)

        with contextlib.ExitStack() as stack:
            if should_flag:
                stack.enter_context(
                    self.assertAddsMessages(
                        testutils.Message(
                            msg_id=mock_patch_autospec.MockPatchAutospecChecker.name,
                            node=patch_call,
                            args=(f"{fixture_name}.{func_name}",),
                        ),
                    )
                )
            else:
                stack.enter_context(self.assertNoMessages())

            self.checker.visit_call(patch_call)

    @pytest.mark.parametrize("call_args", _MOCK_PATCH_DICT_TEST_CASES)
    def test_mock_dict(self, source_template, call_args):
        source_code = source_template.format(
            call_args=call_args, func_name="patch.dict"
        )
        patch_call = astroid.extract_node(source_code)

        with self.assertNoMessages():
            self.checker.visit_call(patch_call)
