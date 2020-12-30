"""pytest plugin which filters the collected test targets based on the current shard."""

import os
import logging
import itertools

from rules_128tech import sharder


def pytest_collection_modifyitems(config, items):
    items[:] = sharder.filter_items(items)
