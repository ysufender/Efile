# Efile: Easy Makefile

Efile is a small alternative to Makefiles, written almost entirely in lua and a tiny bit of C.
It has the similar structure of a TOML file, and the feel of a Lua script, since it is plain lua.

Below is the stripped down version of the build script of Efile itself:

```lua
local Efile = require "src.efile"

local project = Efile.Project
    .init("Efile")

    :step(Efile.Step
        .init("bundle")
        :action("mkdir -p build")
        :action(AMALG..AMALGFLAGS)
        :action(to_header))

    :step(Efile.Step
        .init("build")
        :dependOn("bundle")
        :action(CC..CFLAGS.."src/efile.c -o build/efile -llua -lm -ldl"))

    :step(Efile.Step
        .init("install")
        :dependOn("build")
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
        :action("rm -f efile efile_bundle.lua efile_bundle.h"))

local result = Efile.Project.build(project, arg[1] or "build") or "Success"
print(result)
```

As you can see, you can create and configure your build files in an (almost) declarative way.

## Using Efile

Efile is a small Lua library at its core. So, techincally all you have to do is copy the `src/` contents
into your `script/` (or whatever you'd like) folder and require the `efile` module. You can then invoke
your build script as a plain lua file, like: `lua your_build_script.lua` and it'll work just fine.

Or if you want to have some sort of `efile` utility that'll detect a `build.lua` file and call it automatically,
you can build Efile executable from source. Efile build script is written using Efile itself too!

## Building From the Source

To build efile, either, use        : `efile build` or `lua build.lua build`,
To install efile on your path, use : `efile install` or `lua build.lua install`

Build files will be written to `build/`.
