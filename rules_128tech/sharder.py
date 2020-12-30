"""Add support for sharding tests using bazel."""

import os
import logging
import itertools

LOG = logging.getLogger(__name__)


def filter_items(items):
    """Filter a list of items to test based on the current shard."""
    _notify_bazel_we_support_sharding()

    try:
        total_shards = int(os.environ["TEST_TOTAL_SHARDS"])
        shard_index = int(os.environ["TEST_SHARD_INDEX"])
    except (KeyError, ValueError):
        return items

    bucket_iterator = itertools.cycle(range(total_shards))

    return [
        item for item, bucket in zip(items, bucket_iterator) if bucket == shard_index
    ]


def _notify_bazel_we_support_sharding():
    try:
        path = os.environ["TEST_SHARD_STATUS_FILE"]
    except KeyError:
        return

    try:
        with open(path, mode="w") as f:
            f.write("")
    except (OSError, IOError):
        LOG.error("Error opening TEST_SHARD_STATUS_FILE (%s)" % path)
