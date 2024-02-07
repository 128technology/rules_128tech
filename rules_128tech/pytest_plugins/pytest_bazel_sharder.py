"""pytest plugin which filters the collected test targets based on the current shard."""

import pytest

from rules_128tech import sharder


# pytest-randomly uses tryfirst=True, so this is a hookwrapper to ensure that sharding
# happens before test shuffling. Otherwise, each shard would select its test cases
# from a different permutation, possibly resulting in duplicates or missing tests.
@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_collection_modifyitems(items):
    items[:] = sharder.filter_items(items)
    yield
