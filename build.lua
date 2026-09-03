local Efile = require "src.efile"

local project = Efile.Project
    .init("Efile")
    :step(Efile.Step
        .init("build")
        :dependOn("test")
        :action("echo WORKING"))
    :step(Efile.Step
        .init("test")
        :action("echo TESTING"))
    :build("build") or "Success"

print(project)
