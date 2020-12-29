"""Install all pip dependencies."""

load("@pip3_osx//:requirements.bzl", pip3_osx_install = "pip_install")
load("@pip2_osx//:requirements.bzl", pip2_osx_install = "pip_install")
load("@pip3_linux//:requirements.bzl", pip3_linux_install = "pip_install")
load("@pip2_linux//:requirements.bzl", pip2_linux_install = "pip_install")

def pip_install():
    """Install all pip dependencies."""
    pip3_osx_install()
    pip2_osx_install()
    pip3_linux_install()
    pip2_linux_install()
