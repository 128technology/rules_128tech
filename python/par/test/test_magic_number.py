"""This script tests that the "magic_number" library is available for import"""

import magic_number


def main():
    print("Checking the magic number...")
    assert magic_number.get() == 42


if __name__ == "__main__":
    main()
