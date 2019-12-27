"""Environment variable helpers for python binaries"""

load("//private:cfg.bzl", "OPTIMIZE")

_BASE_PYTHON_ENV = {
    "LANG": "en_US.utf8",
    "LC_ALL": "en_US.utf8",
    "PYTHONIOENCODING": "utf-8",
    "PYTHONUNBUFFERED": "1",
}

_BASE_OPTIMIZE_ENV = {
    "PYTHONOPTIMIZE": "1",
}

_BASE_DEFAULT_ENV = {}

def get_python_env(extra_env = {}, default_env = {}, optimize_env = {}):
    """
    Get the python environment dictionary for use with exec_wrapper

    Args:
        extra_env (dict): Extra environment variables to use in every case
            (default: {})

        default_env (dict): Extra environment variables to use only when the
            "//:optimize" flag is not set (default: {})

        optimize_env (dict): Extra environment variables to use only when the
            "//:optimize" config flag is set (default: {})

    Returns:
        select: Selection of the dictionary of environment variables to set
    """
    base_env = dict(_BASE_PYTHON_ENV, **extra_env)

    optimize_env = dict(_BASE_OPTIMIZE_ENV, **optimize_env)
    default_env = dict(_BASE_DEFAULT_ENV, **default_env)

    return select({
        OPTIMIZE: dict(
            base_env,
            **optimize_env
        ),
        "//conditions:default": dict(
            base_env,
            **default_env
        ),
    })
