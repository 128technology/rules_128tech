import contextlib
import functools
import os
import pathlib
import shutil
import sys
import tempfile
import webbrowser
import zipfile
from typing import Iterable, Optional, TextIO

import click
import coverage


# All logs are written to stderr.
# pylint: disable=invalid-name
out = functools.partial(click.secho, err=True, fg="green")
warn = functools.partial(click.secho, err=True, fg="yellow")
err = functools.partial(click.secho, err=True, fg="red")


@contextlib.contextmanager
def chdir_to_workspace_root():
    try:
        workspace = os.environ["BUILD_WORKSPACE_DIRECTORY"]
    except KeyError:
        previous = None
    else:
        previous = pathlib.Path.cwd()
        os.chdir(workspace)

    try:
        yield
    finally:
        if previous is not None:
            os.chdir(str(previous))


@chdir_to_workspace_root()
@click.command(name="collector")
@click.option(
    "--search-root",
    type=click.Path(exists=True),
    default="bazel-testlogs/",
    show_default=True,
    help="The root directory to search for `outputs.zip` containing `.coverage` files.",
)
@click.option(
    "--rcfile",
    type=click.Path(exists=True, file_okay=True, dir_okay=False),
    help="The .coveragerc file containing configuration for reporting coverage.",
)
@click.option(
    "--test-mode",
    default="exclude",
    type=click.Choice(["include", "exclude", "test-only"]),
    show_default=True,
    help=(
        "Include tests in the output report.  "
        "This is usually not too helpful because tests *should* be at 100 percent."
    ),
)
@click.option(
    "--save-merged-data/--no-save-merged-data",
    default=False,
    help=(
        "Write the results of merging all found .coverage files into a single "
        ".coverage at the root of the workspace."
    ),
)
@click.option(
    "--html-report-dir",
    type=click.Path(exists=False, file_okay=False, dir_okay=True),
    default="htmlcov/",
    show_default=True,
    help=(
        "Directory where to write HTML files containing the coverage report.  "
        "The files can be navigated by starting with the main `index.html` file."
    ),
)
@click.option(
    "--xml-report",
    type=click.Path(exists=False, file_okay=True, dir_okay=False),
    help="Path where to write the XML coverage report.",
)
@click.option(
    "--short-report",
    type=click.File("w"),
    default="-",
    show_default=True,
    help="The output where to write a coverage overview.",
)
@click.option(
    "--open-report/--no-open-report",
    default=True,
    show_default=True,
    help="Automatically open the report in the browser.",
)
def main(
    search_root: os.PathLike,
    test_mode: str,
    save_merged_data: bool,
    html_report_dir: os.PathLike,
    xml_report: Optional[os.PathLike],
    short_report: TextIO,
    open_report: bool,
    rcfile: Optional[os.PathLike],
) -> None:
    """
    Collect and combine .coverage files from the results of a `bazel test` run.
    """

    reporter = coverage.coverage(config_file=rcfile)

    with tempfile.TemporaryDirectory() as temp_dir:
        output_dir = pathlib.Path(temp_dir)
        reports = []

        index = 0
        for index, archive in enumerate(find_test_outputs(search_root)):
            report = extract_coverage_report(archive, output=output_dir / f"{index}")
            if report:
                reports.append(report)
            else:
                warn(f"no .coverage found in {archive}")

        if not reports:
            err(
                f"No .coverage files found after finding {index} test outputs under "
                f"the '{search_root}' directory."
            )
            sys.exit(1)

        out(f"combining {len(reports)} coverage reports...")
        reporter.combine(reports)

    if save_merged_data:
        out("writing merged .coverage data")
        reporter.save()

    omit = ["*_test.py"] if test_mode == "exclude" else None
    include = ["*_test.py"] if test_mode == "test-only" else None
    out("generating reports...")
    index = generate_output(
        reporter,
        html_output=html_report_dir,
        short_output=short_report,
        xml_output=xml_report,
        ignore_errors=True,
        omit=omit,
        include=include,
    ).resolve()

    if not open_report or not webbrowser.open(f"file://{index}"):
        out(f"wrote HTML report files to {html_report_dir}")
        out(f"open {index} to view the report.")


def find_test_outputs(search_root: os.PathLike) -> Iterable[pathlib.Path]:
    """
    Find outputs.zip which may or may not container a .coverage file.

    Args:
        search_root: Where to start the search for outputs.zip files. This probably
            should be a `bazel-testlogs` directory.
    """

    # See the following two links for more about this glob.
    # https://stackoverflow.com/questions/47871993/bazel-writable-archivable-path-for-test-runtime
    # https://docs.bazel.build/versions/master/test-encyclopedia.html#test-interaction-with-the-filesystem
    return pathlib.Path(search_root).glob("**/test.outputs/outputs.zip")


def extract_coverage_report(
    archive: pathlib.Path, output: pathlib.Path
) -> Optional[pathlib.Path]:
    """
    Open a zip and check if it contains a .coverage file.

    Args:
        archive: The name of the zip file.
        output: Where to write the .coverage (if found!)

    Returns:
        Where the .coverage was written to.
    """
    with zipfile.ZipFile(archive, mode="r") as zip_:
        try:
            with zip_.open(".coverage", mode="r") as file_:
                output.write_bytes(file_.read())
        except OSError:
            return None

    return output


def generate_output(
    reporter: coverage.coverage,
    html_output: os.PathLike,
    short_output: TextIO,
    xml_output: Optional[os.PathLike],
    **kwargs,
) -> pathlib.Path:
    """
    Generate the coverage report. The TLDR is written to stdout, and the full report
    is written to a directory containing HTML.

    Args:
        reporter: The coverage object
        html_output: The directory where to write the HTML report
        **kwargs: Any arguments to pass to coverage.coverage.report

    Returns:
        The path to the index.html, which is the starting point for the report.
    """
    html_output = pathlib.Path(html_output)
    shutil.rmtree(html_output, ignore_errors=True)
    reporter.html_report(directory=str(html_output), **kwargs)
    if xml_output:
        reporter.xml_report(outfile=str(xml_output), **kwargs)
    reporter.report(file=short_output, **kwargs)
    return html_output / "index.html"


if __name__ == "__main__":
    main()  # pylint: disable=no-value-for-parameter
