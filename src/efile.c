#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "efile_bundle.h"

static int preload_efile(lua_State *luaState) {
    if (luaL_loadbuffer(luaState, (const char *)efile_bundle, efile_bundle_len, "@efile") != LUA_OK) {
        return lua_error(luaState);
    }
    lua_call(luaState, 0, 1);
    return 1;
}

static void register_preload(lua_State *luaState) {
    lua_getglobal(luaState, "package");
    lua_getfield(luaState, -1, "preload");
    lua_pushcfunction(luaState, preload_efile);
    lua_setfield(luaState, -2, "efile");
    lua_pop(luaState, 2);
}

static void push_args(lua_State *luaState, int argc, char **argv) {
    lua_createtable(luaState, argc - 1, 1);
    for (int i = 0; i < argc; i++) {
        lua_pushstring(luaState, argv[i]);
        lua_rawseti(luaState, -2, i);
    }
    lua_setglobal(luaState, "arg");
}

int main(int argc, char **argv) {
    if (argc < 1) {
        fprintf(stderr, "Usage: efile [args...]\n");
        return 1;
    }

    const char *script = "build.lua";

    lua_State *luaState = luaL_newstate();
    luaL_openlibs(luaState);

    register_preload(luaState);
    push_args(luaState, argc, argv);

    if (luaL_dofile(luaState, script) != LUA_OK) {
        fprintf(stderr, "efile: %s\n", lua_tostring(luaState, -1));
        lua_close(luaState);
        return 1;
    }

    lua_close(luaState);
    return 0;
}
