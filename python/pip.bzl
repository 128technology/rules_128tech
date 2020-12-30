"""
Repository rule for creating layers of indirection that allow a cross-platform python experience.
"""

_ROOT_BUILD_TEMPLATE = """
config_setting(
    name = "{name}",
    values = {values},
)
""".strip()

_PACKAGE_BUILD_TEMPLATE = """
{load_statements}

package(default_visibility = ["//visibility:public"])

alias(
    name = "{name}",
    actual = select({{
{select_conditions}
    }})
)
""".strip()

def _safe_name(name):
    return name.lower().replace("-", "_")

def _parse_requirements(file_contents):
    return [
        line.split(" ")[0]
        for line in file_contents.splitlines()
    ]

def _generate_root_build_file(repository_ctx):
    config_setting = repository_ctx.attr.new_config_setting

    if config_setting:
        build_file_contents = _ROOT_BUILD_TEMPLATE.format(
            name = config_setting,
            values = repository_ctx.attr.new_config_values,
        )
    else:
        build_file_contents = ""

    repository_ctx.file(
        "BUILD",
        content = build_file_contents,
    )

def _generate_requirements_bzl(repository_ctx):
    repository_ctx.file(
        "requirements.bzl",
        content = """
def requirement(name):
    \"\"\"Proxy the request for the requirement to the sub-package.\"\"\"
    return "//" + _safe_name(name)

def _safe_name(name):
    return name.lower().replace("-", "_")
""",
    )

def _generate_package_build_file(repository_ctx, name):
    select_conditions = [
        " " * 8 + '"{config_setting}": {repo}_requirement("{name}"),'.format(
            config_setting = config_setting,
            repo = repo,
            name = name,
        )
        for config_setting, repo in repository_ctx.attr.select.items()
    ]

    safe_name = _safe_name(name)
    load_statements = [
        """load("@{repo}//:requirements.bzl", {repo}_requirement = "requirement")""".format(repo = repo)
        for repo in repository_ctx.attr.select.values()
    ]

    repository_ctx.file(
        "%s/BUILD" % safe_name,
        content = _PACKAGE_BUILD_TEMPLATE.format(
            name = safe_name,
            load_statements = "\n".join(load_statements),
            select_conditions = "\n".join(select_conditions),
        ),
    )

def _impl(repository_ctx):
    if bool(repository_ctx.attr.new_config_setting) != bool(repository_ctx.attr.new_config_values):
        fail("If 'new_config_setting' or 'new_config_values' are specified, both must be")

    per_repo_requirements = {
        requirements_file.name: _parse_requirements(repository_ctx.read(requirements_file))
        for requirements_file in repository_ctx.attr.requirements
    }

    requirement_count = {}

    for requirement_list in per_repo_requirements.values():
        for requirement in requirement_list:
            new_count = requirement_count.setdefault(requirement, 0) + 1
            requirement_count[requirement] = new_count

    output_requirements = sorted([
        requirement
        for requirement, count in requirement_count.items()
        if count == len(per_repo_requirements)
    ])

    _generate_root_build_file(repository_ctx)

    _generate_requirements_bzl(repository_ctx)

    for package_name in output_requirements:
        _generate_package_build_file(repository_ctx, package_name)

pip_aliases = repository_rule(
    attrs = {
        "new_config_setting": attr.string(
            doc = "create a new `config_setting` to `select` on. ",
            mandatory = False,
        ),
        "new_config_values": attr.string_dict(
            doc = "`values` attribute of the new `config_setting` to select on",
            mandatory = False,
        ),
        "requirements": attr.label_list(
            doc = "requirements files. A package must be present in ALL of them to generate an alias",
            mandatory = True,
            allow_empty = False,
            allow_files = True,
        ),
        "select": attr.string_dict(
            doc = "config settings to `select` on. Keys should be `config_setting` names and " +
                  "values should be repository names",
            mandatory = True,
            allow_empty = False,
            default = {},
        ),
    },
    implementation = _impl,
    doc = "create a WORKSPACE that `select`s between multiple python versions.",
)
