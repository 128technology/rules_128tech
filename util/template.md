<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#template"></a>

## template

<pre>
template(<a href="#template-name">name</a>, <a href="#template-out">out</a>, <a href="#template-src">src</a>, <a href="#template-substitutions">substitutions</a>)
</pre>

Simple wrapper around generating a template from a macro or BUILD file

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| out |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| src |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| substitutions |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |


