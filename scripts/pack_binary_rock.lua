#!/usr/bin/env -S nvim -u NONE -U NONE -N -i NONE -l

local argc = #arg
if argc ~= 2 then
  error("expected rock name arg and platform arg")
end
local rock_name = arg[1]
local arch = arg[2]

local luarocks_cmd
if vim.uv.os_uname().sysname:lower():find("windows") then
  -- HACK: Hardcode luarocks path, as it can't seem to be found by vim.system.
  luarocks_cmd = vim.print(assert(vim.fn.glob("C:/Users/runneradmin/scoop/apps/luarocks/current/luarocks"), "luarocks executable not found"))
else
  luarocks_cmd = "luarocks"
end

local ok, err = pcall(vim.system, { luarocks_cmd, "search", "--porcelain", rock_name}, nil)
local sc
if ok then
  sc = err:wait()
else
  sc = {
      code = 1,
      signal = 0,
      stderr = ("Failed to invoke luarocks at %s: %s"):format(luarocks_cmd, err),
  }
end
if sc.code ~= 0 then
  error("Error searching for " .. rock_name .. ":\n" .. vim.inspect(sc))
end
local output = sc.stdout

local function get_latest_version(version_str_iterator)
  return vim.iter(version_str_iterator)
    :map(function(version)
      -- remove -<scm>
      return version:match("([^-]+)")
    end):filter(function(version_str)
      return version_str ~= nil
    end):map(function(version_str)
      local ok, version = pcall(vim.version.parse, version_str)
      if ok then
        return version
      end
    end):filter(function(version)
      return version ~= nil
    end):fold(nil, function(latest_sofar, version)
      return latest_sofar and latest_sofar > version and latest_sofar or version
    end)
end

local version_iter = vim.iter(output:gmatch("(%S+)%s+(%S+)%s+[^\n]+"))
  :map(function(name, version)
    if name == rock_name then
      return version
    end
  end)
local latest_version = get_latest_version(version_iter)
if not latest_version then
  error("Could not determine latest version of " .. rock_name)
end

local manifest = {}
loadfile("manifest-5.1", "t", manifest)()

local packed_versions = vim.iter(manifest.repository[rock_name] or {})
  :fold({}, function(acc, version, architectures)
    vim.iter(architectures):each(function(arch_tbl)
      if arch_tbl.arch == arch then
        table.insert(acc, version)
      end
    end)
    return acc
  end)
local latest_packed_version = get_latest_version(packed_versions)

print(([[
%s:
Latest version on luarocks.org: %s
Packed version: %s
Latest packed version: %s
]]):format(rock_name, tostring(latest_version), vim.inspect(packed_versions), tostring(latest_packed_version or "NONE")))

if latest_packed_version and latest_packed_version >= latest_version then
  print("Nothing to do.")
  return
end

sc = vim.system({ luarocks_cmd, "--local", "--lua-version=5.1", "install", rock_name, latest_version}):wait()

if sc.code ~= 0 then
  print(sc.stdout and "STDOUT:\n" .. sc.stdout)
  print(sc.stderr and "STDERR:\n" .. sc.stderr)
  error("luarocks install failed!")
end

sc = vim.system({ luarocks_cmd, "pack", rock_name}):wait()

if sc.code ~= 0 then
  print(sc.stdout and "STDOUT:\n" .. sc.stdout)
  print(sc.stderr and "STDERR:\n" .. sc.stderr)
  error("luarocks pack failed!")
end
