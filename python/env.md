<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#get_python_env"></a>

## get_python_env

<pre>
get_python_env(<a href="#get_python_env-extra_env">extra_env</a>, <a href="#get_python_env-default_env">default_env</a>, <a href="#get_python_env-optimize_env">optimize_env</a>)
</pre>

    Get the python environment dictionary for use with exec_wrapper

**PARAMETERS**


| Name  | Description | Default Value |
| :-------------: | :-------------: | :-------------: |
| extra_env |  Extra environment variables to use in every case     (default: {})   |  <code>{}</code> |
| default_env |  Extra environment variables to use only when the     "//:optimize" flag is not set (default: {})   |  <code>{}</code> |
| optimize_env |  Extra environment variables to use only when the     "//:optimize" config flag is set (default: {})   |  <code>{}</code> |


