"""Install all pip dependencies."""

load("@pip2_current//:requirements.bzl", pip2_install = "pip_install")
load("@pip3_current//:requirements.bzl", pip3_install = "pip_install")

def pip_install():
    """Install all pip dependencies."""
    pip2_install()
    pip3_install()
