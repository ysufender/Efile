local Efile = require "src.efile"

local AMALG      = "amalg.lua "
local AMALGFLAGS = "-o "
                   .."build/efile_bundle.lua "
                   .."-s "
                    .."src/efile.lua "
                    .."src.build_system.project "
                    .."src.build_system.step "

local CC     = "gcc "
local CFLAGS = "-I/usr/include/lua5.4 "
               .."-Ibuild/ "
               .."-O2 -Wall -Wextra "

---@type fun(): nil
local to_header do
    to_header = function ()
        local f = io.open("build/efile_bundle.lua", "rb")
        if not f then return "Failed to open build/efile_bundle.lua" end
        local data = f:read("*a")
        f:close()
        local out = io.open("build/efile_bundle.h", "w")
        if not out then return "Failed to write efile_bundle.h" end
        out:write("/* Auto-generated */\nunsigned char efile_bundle[] = {\n  ")
        for i = 1, #data do
            out:write(string.format("0x%02x, ", data:byte(i)))
            if i % 12 == 0 then out:write("\n  ") end
        end
        out:write("\n};\nunsigned int efile_bundle_len = " .. #data .. ";\n")
        out:close()
    end
end

local project = Efile.Project
    .init("Efile")

    :step(Efile.Step
        .init("bundle")
        :dependOn({ file = "build.lua" })
        :dependOn({ file = "src/efile.lua" })
        :dependOn({ file = "src/build_system/project.lua" })
        :dependOn({ file = "src/build_system/step.lua" })
        :action(AMALG..AMALGFLAGS)
        :action(to_header))

    :step(Efile.Step
        .init("build")
        :dependOn("bundle")
        :dependOn({ file = "src/efile.c" })
        :action(CC..CFLAGS.."src/efile.c -o build/efile -llua5.4 -lm -ldl"))

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
