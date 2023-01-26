"""Install all pip dependencies."""

load("@pip3_current//:requirements.bzl", pip3_install = "pip_install")

def pip_install():
    """Install all pip dependencies."""
    pip3_install()
