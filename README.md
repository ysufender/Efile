# Efile: Easy Makefile

> Note: EFILE IS NOT CROSSPLATFORM, IT DEPENDS ON UNIX SHELL UTILITIES

Efile is a small alternative to Makefiles, written almost entirely in Lua and a tiny bit of C.
It has the similar structure of a TOML file, and the feel of a Lua script, since it is plain lua.

Below is the stripped down version of the build script of Efile itself:

```lua
local project = Efile.Project
    .init("Efile")

    :step(Efile.Step
        .init("bundle")
        :dependOnFiles({
            "build.lua",
            "efile/efile.lua",
            "efile/build_system/project.lua",
            "efile/build_system/step.lua",
        })
        :action(AMALG..AMALGFLAGS)
        :action(to_header))

    :step(Efile.Step
        .init("build")
        :dependOnFile("efile/efile.c")
        :dependOnStep("bundle")
        :action(CC..CFLAGS.."efile/efile.c -o build/efile -l\"lua5.4\" -lm -ldl"))

    :step(Efile.Step
        .init("install")
        :dependOnStep("build")
        :action("sudo install -m 755 build/efile /usr/local/bin/efile"))

    :step(Efile.Step
        .init("help")
        :action(function ()
            print("Usage:\n\tlua build.lua <target>\n\tefile <target>")
            print("\nTargets:")
            print("    bundle : bundle efile sources")
            print("    build  : build efile executable")
            print("    install: install efile on system")
            print("    help   : print this help text")
            print("    clean  : clean")
        end))

    :step(Efile.Step
        .init("clean")
        :action("rm -rf build"))

local result = project:build(arg[1] or "build") or "Success"
print(result)
```

As you can see, you can create and configure your build files in an (almost) declarative way.

## Using Efile

Efile is a small Lua library at its core. So, techincally all you have to do is copy the `src/` contents
into your `script/` (or whatever you'd like) folder and require the `efile` module. You can then invoke
your build script as a plain lua file, like: `lua your_build_script.lua` and it'll work just fine.

Or if you want to have some sort of `efile` utility that'll detect a `build.lua` file and call it automatically,
you can build Efile executable from source. Efile build script is written using Efile itself too!

### Creating A Project

Efile works in Projects and Steps, each Project is a collection of steps and each Step is a collection
of Dependencies and Actions. Efile is designed in a `Factory` style to increase ease of use and ease
of reading.

To create an Efile project, simply initialize one like so:

```lua
local Efile = require "efile"

local project = Efile.Project.init("First_Project")
```

`Efile.Project.init` creates and returns an Efile project, but this will change in the next section
when we introduce Step chains.

In this state, the Efile will not do anything, that is because we initialized the Project but did not
build it. To build it, simply call the `build` function:

```lua
local result = Efile.Project.build(project, "step_name") or "Success"
print(result)
```

`Efile.Project.Build` function returns `string?`, `nil` on success and the error message in case of
a failure. This decision was made due to the possibility of multiple projects existing in the same
Efile. For this reason, a project may not simply abort the whole process in case of an error.

If you save this to a `build.lua` and execute `efile` or `lua build.lua`, you'll see a message like:

`No steps to run`

since we have no steps to run.

### Adding Steps

Steps are the equivalent of Makefile rules in Efile. To create a step, call the `Efile.Step.init` function,
and pass it to the `Efile.Project.step` method on the project, like:

```lua
local Efile = require "efile"

local project = Efile.Project
    .init("First_Project")
    
    :step(Efile.Step
        .init("build"))
```

This chain call will populate the Project with the given step. We can modify the build call a little
to execute our step now:

```lua
local result = Efile.Project.build(project, "build") or "Success"
print(result)
```

If you run this build file, the output will simply be `Success`, since our build step doesn't do anything
notable, yet alone anything at all. We can add `actions` to the Step to make it a little more useful.

You can also add multiple steps at once using the `multiStep` method. We'll see that in the [Advanced Efile](#advanced-efile)

#### Adding Actions To Steps

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("build")
        :action("echo Hello World"))
```

If you run the script this time, you'll be greeted by a `Hello World`. Well actually you'll see something like:

```bash
> Executing command 'echo Hello World'
>> Hello World

Success
```

but I guess it is close enough.

If you have more complex tasks that you must do, you can pass a function with the signature `fun(): string?`
as an action too!

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("build")
        :action("echo Hello World")
        :action(function()
            print("I am an action as well.")
        end))
```

And the output will be:

```bash
> Executing command 'echo Hello World'
>> Hello World

I am an action as well.
Success
```

And if you return a non-null string from the function, the output will be:

```bash
> Executing command 'echo Hello World'
>> Hello World

I am an action as well.
Oh no, an error!
....Required from 'build'
Build failed.
```

#### Adding Prebuild Actions To Steps

Sometimes you might want to execute some actions before the dependencies are called.
For that reason, you can add prebuild actions to steps like:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("build")
        :dependOn("some_other_step")
        :pre("echo This Will Execute Before the Dependencies")
        :action("echo Hello World")
        :action(function()
            print("I am an action as well.")
        end))

    :step(Efile.Step
        .init("some_other_step")
        :action("echo This is the dependency"))
```

#### Adding File Dependencies To Steps

A proper Efile should not do extra work when it doesn't have to do. For example if the build script has not
changed, and that we don't depend on anything else, why run the build script?

To add a file as a dependency, and cache its modification time, we use the `dependOnFile` method like so:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("build")
        :dependOnFile("build.lua")
        :action("echo Hello World")
```

Now if we run this for the first time, we'll see the `Hello World` message, but if we run a second time
without touching the build script, we'll only see `Success`. And as usual, you can add as many file dependencies
as you'd like by chaining `dependOnFile` calls.

Alternatively, if you depend on many files, you can use the `dependOnFiles` method:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("build")
        :dependOnFiles({
            "build.lua",
            "otherfile.lua",
            "yetanotherfile.lua"
        })
        :action("echo Hello World")
```

> Note: File dependencies are relative to the build script's base folder.

#### Adding Step Dependencies

Let's assume that we have a project structure that looks like this:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("generate")
        :action("mkdir -p test_folder"))

    :step(Efile.Step
        .init("build")
        :dependOnFile("test.lua")
        :action("ls -la")
```

In this situation, our `build` Step depends on not only `test.lua`, but also the `generate` step. To add
it as a dependency, we simply do:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("generate")
        :action("mkdir -p test_folder"))

    :step(Efile.Step
        .init("build")
        :dependOnFile("build.lua")
        :dependOnStep("generate")
        :action("ls -la"))
```

If you have multiple dependencies of steps however, you can use `dependOnSteps` method:

```lua
local project = Efile.Project
    .init("First_Project")

    :step(Efile.Step
        .init("gneerate")
        :action("mkdir -p test_folder"))

    :step(Efile.Step
        .init("build")
        :dependOnFile("build.lua")
        :dependOnSteps({
            "generate",
            "someotherstep"
        })
        :action("ls -la"))
```

If you now execute the build script, it will first create the folder and then call `ls -la`.

If at least one of the dependencies is marked as `to_build` by the build system (depending on their own
dependencies of both kinds), a Step is too marked as `to_build`.

## Advanced Efile

Since Efile is plain Lua, you can make up some pretty wild techniques. But I'll give a small one for
example. Below is an Efile, that uses a function to generate necessary steps from a list of source files:

```lua
local Efile = require "efile.efile"

local cc      = "gcc "
local ld      = "gcc "
local cflags  = "-Wall -Wextra -Werror -c "
local ldflags = ""

local csources = {
    "main.c",
    "file/at/subpath.c"
}

local function generate_ld_step(sources, output)
    local object_files = ""

    for _, source in ipairs(sources) do
        local full_file_no_ext = string.match(source, "^(.+)%.[^%.]+$")
        object_files = object_files..full_file_no_ext..".o "
    end

    return Efile.Step
        .init("link")
        :dependOnStep("compile")
        :pre("mkdir -p build/bin/")
        :action(ld..ldflags..object_files.." -o build/bin/"..output)
end

local function generate_cc_steps(sources)
    local compile_step = Efile.Step.init("compile")
    local steps = {}

    for _, source in ipairs(sources) do
        local base_file = string.match(source, "([^/]+)$")
        local full_file_no_ext = string.match(source, "^(.+)%.[^%.]+$")

        local new_step = Efile.Step
            .init(base_file)
            :dependOnFile(source)
            :action(cc..cflags..source.." -o build/"..full_file_no_ext..".o")

        table.insert(steps, new_step)
        compile_step:dependOnStep(new_step.name)
    end

    table.insert(steps, compile_step)
    return steps
end

local project = Efile.Project
    .init("Test")
    :multiStep(generate_cc_steps(csources))
    :step(generate_ld_step(csources, "test"))

for _, step in pairs(project.steps) do
    print(step.name..": "..tostring(step.actions[1]))
end
```

Should output something the sorts of:

```bash
main.c: gcc -Wall -Wextra -Werror -c main.c -o build/main.o
link: gcc main.o file/at/subpath.o  -o build/bin/test
compile: nil
subpath.c: gcc -Wall -Wextra -Werror -c file/at/subpath.c -o build/file/at/subpath.o
```

Now if you want to add another source file, you just have to add it to the `csources` list. You can
do something about the same for include directories, libraries and link directories as well.

## Building From the Source

To build efile, either, use        : `efile build` or `lua build.lua build`,
To install efile on your path, use : `efile install` or `lua build.lua install`

Build files will be written to `build/`.
