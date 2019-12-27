<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#exec_wrapper"></a>

## exec_wrapper

<pre>
exec_wrapper(<a href="#exec_wrapper-name">name</a>, <a href="#exec_wrapper-env">env</a>, <a href="#exec_wrapper-exe">exe</a>, <a href="#exec_wrapper-static_args">static_args</a>)
</pre>


Generates a BASH script to use as wrapper around another executable

This allows specific environment variables to be set or arguments to be passed


**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| env |  environment variables to set during execution   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| exe |  a path to an executable   | String | required |  |
| static_args |  arguments that should always be passed to the executable   | List of strings | optional | [] |


