<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#pip_aliases"></a>

## pip_aliases

<pre>
pip_aliases(<a href="#pip_aliases-name">name</a>, <a href="#pip_aliases-new_config_setting">new_config_setting</a>, <a href="#pip_aliases-new_config_values">new_config_values</a>, <a href="#pip_aliases-requirements">requirements</a>, <a href="#pip_aliases-select">select</a>)
</pre>

create a WORKSPACE that `select`s between multiple python versions.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this repository.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| new_config_setting |  create a new <code>config_setting</code> to <code>select</code> on.   | String | optional | "" |
| new_config_values |  <code>values</code> attribute of the new <code>config_setting</code> to select on   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| requirements |  requirements files. A package must be present in ALL of them to generate an alias   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | required |  |
| select |  config settings to <code>select</code> on. Keys should be <code>config_setting</code> names and values should be repository names   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | required |  |


