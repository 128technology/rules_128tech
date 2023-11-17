"""
Repack a bazel python_zip_file (the same thing generated by specifying 'bazel build
--build_python_zip') into a tarfile that extracts into a runnable application.
"""

import argparse
import io
import pathlib
import re
import tarfile
import zipfile

# Based on https://github.com/128technology/subpar/blob/4ae9bb7d37eaf6397d38739ad46c9be0a15e70c8/compiler/python_archive.py#L49
# Boilerplate code added to __main__.py
_boilerplate = b"""\
# Boilerplate added by @rules_128tech//python/py_unzip:rezipper.py
def _():
    import os
    os.environ["ORIGINAL_PYTHONPATH"] = os.environ["PYTHONPATH"]
    os.environ["PYTHONPATH"] = ""
_()
del _
# End boilerplate
"""

# Boilerplate must be after the last __future__ import.  See
# https://docs.python.org/2/reference/simple_stmts.html#future
_boilerplate_insertion_regex = re.compile(
    b'''(?sx)
(?P<before>
    (
        (
            ([#][^\\r\\n]*) | # comment
            (\\s*) | # whitespace
            (from\\s+__future__\\s+import\\s+[^\\r\\n]+) | # future import
            ('[^'].*?') | # module doc comment form 1
            ("[^"].*?") | # module doc comment form 2
            (\'\'\'.*?(\'\'\')) | # module doc comment form 3
            (""".*?""") # module doc comment form 4
        )
        [\\r\\n]+ # end of line(s) for Mac, Unix and/or Windows
    )*
)
# Boilerplate is inserted here
(?P<after>.*)
'''
)


def main():
    args = _parse_args()
    run(
        src=args.src,
        dst=args.dst,
        package_dir=args.package_dir,
        main=args.main,
        real_main=args.real_main,
    )


def _parse_args():
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument(
        "--src",
        help="Path to the source .zip file.",
        required=True,
    )
    parser.add_argument(
        "--dst",
        help="Path to the output .tar file.",
        required=True,
    )
    parser.add_argument(
        "--package-dir",
        help="The directory in which to expand the specified files.",
        type=pathlib.Path,
        required=True,
    )
    parser.add_argument(
        "--main",
        help="The __main__.py for the output tar.",
        type=pathlib.Path,
        required=True,
    )
    parser.add_argument(
        "--real-main",
        help="Path to the user-supplied __main__.py.",
        required=True,
    )
    return parser.parse_args()


def run(
    src: str,
    dst: str,
    package_dir: pathlib.Path,
    main: pathlib.Path,
    real_main: str,
):
    found_main = found_real_main = False

    with zipfile.ZipFile(src, "r") as z_in:
        with tarfile.TarFile(dst, "w") as z_out:
            addfile = _make_addfile(z_out, package_dir)

            for info in z_in.infolist():
                # Override the __main__.py from the python_zip_file.
                if info.filename == "__main__.py":
                    addfile(info.filename, main.read_bytes(), mode=0o755)
                    found_main = True
                # Insert boilerplate into the user's __main__.py
                elif info.filename.endswith(real_main):
                    addfile(
                        info.filename,
                        insert_boilerplate(z_in.read(info.filename)),
                        mode=info.external_attr >> 16 or 0o644,
                    )
                    found_real_main = True
                else:
                    addfile(
                        info.filename,
                        z_in.read(info.filename),
                        mode=info.external_attr >> 16 or 0o644,
                    )

        assert found_main, f"missing __main__.py in {z_in.namelist()}"
        assert found_real_main, f"missing real main {real_main!r} in {z_in.namelist()}"

def _make_addfile(z_out: tarfile.TarFile, package_dir: pathlib.Path):
    def addfile(filename: str, data: bytes, *, mode: int) -> None:
        tarinfo = tarfile.TarInfo(str(package_dir / filename))
        tarinfo.size = len(data)
        tarinfo.mode = mode
        z_out.addfile(tarinfo, io.BytesIO(data))

    return addfile


def insert_boilerplate(original_content: bytes) -> bytes:
    # Find a good place to insert the boilerplate, which is the
    # first line that is not a comment, blank line, doc comment,
    # or future import.
    match = re.match(_boilerplate_insertion_regex, original_content)
    assert match, original_content
    assert (len(match.group("before")) + len(match.group("after"))) == len(
        original_content
    ), (match, original_content)
    return match.group("before") + _boilerplate + match.group("after")


if __name__ == "__main__":
    main()
