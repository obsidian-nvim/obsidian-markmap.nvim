local api = require("obsidian.api")

local function get_plugin_dir()
	local str = debug.getinfo(2, "S").source:sub(2)
	return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(str))))
end

---@return boolean
local function has_global_cli()
	-- return api.get_external_dependency_info("markmap")
	return false
end

---@return boolean
local function has_npm()
	return api.get_external_dependency_info("npm") ~= nil
end

local function install_local_cli(f)
	if not has_npm() then
		return vim.notify("no npm")
	end

	vim.system({ "npm", "install", "markmap-cli" }, {
		cwd = get_plugin_dir(),
	}, function(out)
		assert(out.code == 0)
		f()
	end)
end

local function get_cli_path()
	if has_global_cli() then
		return "markmap"
	else
		return vim.fs.joinpath(get_plugin_dir(), "node_modules", "markmap-cli", "bin", "cli.js")
	end
end

---@param note obsidian.Note?
local function run_markmap(note)
	assert(note, "no note")
	local cli_path = get_cli_path()

	local cmds = {
		cli_path,
		tostring(note.path),
	}

	local function run_cmd()
		vim.system(cmds, {}, function(out)
			assert(out.code == 0)
		end)
	end

	if vim.fn.executable(cli_path) == 1 then
		run_cmd()
	else
		vim.notify("Installing markmap...")
		install_local_cli(function()
			run_cmd()
		end)
	end
end

---@param client obsidian.Client
return function(client)
	local note = client:current_note()
	if not note then
		return
	end
	run_markmap(note)
end
