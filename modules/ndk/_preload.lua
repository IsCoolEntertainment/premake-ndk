--
-- Copyright (c) 2014 Will Vale and the Premake project
--

local p = premake
local project   = p.project
local config    = p.config

-- Register the action
newaction {
	trigger     = "ndk-manifest",
	shortname   = "Android NDK manifest",
	description = "Generate manifest and other app build files for Android",

	-- The capabilities of this action
	valid_kinds     = { "WindowedApp", "StaticLib", "SharedLib" },
	valid_languages = { "C", "C++" },
	valid_tools     = {
		cc     = { "gcc" },
	},

	onsolution = function(sln)
		-- Nothing to do here
	end,

	onproject = function(prj)
		-- Not all projects are valid
		if not p.modules.ndk.isValidProject(prj) then
			return
		end

		-- Need to generate one makefile per configuration
		for cfg in project.eachconfig(prj) do
			if cfg.platform ~= p.modules.ndk.ANDROID then
				error('The only supported platform for NDK builds is "android"')
			end		

			if cfg.kind == premake.WINDOWEDAPP then
				-- Generate the manifest for application projects only

				-- Define closure to pass config
				function generateManifestCallback(prj)
					p.modules.ndk.generateManifest(prj, cfg)
				end

				-- Generate the manifest
				premake.generate(prj, p.modules.ndk.getManifestFilename(prj, cfg), generateManifestCallback)

				-- Produce the activity glue source, if possible.
				if cfg.activity and cfg.baseactivity and cfg.packagename and cfg.basepackagename then
					-- Define closure - we need to tell the project which file to generate.
					function generateActivityCallback(prj)
						p.modules.ndk.generateActivity(prj, cfg)
					end

					-- Generate activity source
					premake.generate(prj, p.modules.ndk.getActivityFilename(prj, cfg), generateActivityCallback) 
				end

				-- Export Java source
				for _,v in ipairs(cfg.files) do
					if path.getextension(v) == p.modules.ndk.JAVA then
						if os.isfile(v) then
							local dst = path.join(p.modules.ndk.getJavaPath(prj, cfg), path.getname(v))
							printf('Exporting %s...', path.getrelative(os.getcwd(), dst))
							os.copyfile(v, dst)
						end
					elseif not path.iscppfile(v) and not path.iscfile(v) and not path.iscppheader(v) and path.getextension(v) ~= '.lua' then
						if os.isfile(v) then
							local dir = p.modules.ndk.getAssetPath(prj, cfg)
							os.mkdir(dir)
							local dst = path.join(dir, path.getname(v))
							printf('Exporting %s...', path.getrelative(os.getcwd(), dst))
							os.copyfile(v, dst)
						end
					end
				end
			end
		end
	end,

	oncleansolution = function(sln)
		-- Nothing to do
	end,

	oncleanproject = function(prj)
		for cfg in project.eachconfig(prj) do
			if prj.kind == premake.WINDOWEDAPP then
				-- Just clean the entire folder.
				premake.clean.dir(prj, p.modules.ndk.getProjectPath(prj, cfg))
			end
		end
	end
}

-- Register the action with Premake.
newaction {
	trigger     = "ndk-makefile",
	shortname   = "Android NDK makefiles",
	description = "Generate makefiles for Android ndk-build",

	-- The capabilities of this action
	valid_kinds     = { "WindowedApp", "StaticLib", "SharedLib" },
	valid_languages = { "C", "C++" },
	valid_tools     = {
		cc     = { "gcc" },
	},

	onsolution = function(sln)
		-- There isn't anything meaningful to generate for solutions. ndk-build is really intended to 
		-- compile and link together all the components for a given app.
	end,

	onproject = function(prj)
		-- Not all projects can generate something sensible.
		if  not p.modules.ndk.isValidProject(prj) then
			return
		end

		-- Need to generate one makefile per configuration
		for cfg in project.eachconfig(prj) do
			if cfg.platform ~= p.modules.ndk.ANDROID then
				error('The only supported platform for NDK builds is "android"')
			end		

			-- Define closure to pass config
			function generateMakefileCallback(prj)
				p.modules.ndk.generateMakefile(prj, cfg)
			end
			function generateAppMakefileCallback(prj)
				p.modules.ndk.generateAppMakefile(prj, cfg)
			end

			-- Generate the ndk-build makefile
			local makefileName = p.modules.ndk.getMakefileName(prj, cfg, p.modules.ndk.MAKEFILE)
			local makefileTempName = makefileName .. ".tmp"
			
			premake.generate(prj, makefileTempName, generateMakefileCallback)
			p.modules.ndk.compareAndUpdate(makefileTempName, makefileName)

			if cfg.kind == premake.WINDOWEDAPP then
				-- Generate the application makefile for application projects only
				makefileName = p.modules.ndk.getMakefileName(prj, cfg, p.modules.ndk.APPMAKEFILE)
				makefileTempName = makefileName .. ".tmp"
				
				premake.generate(prj, makefileTempName, generateAppMakefileCallback)
				p.modules.ndk.compareAndUpdate(makefileTempName, makefileName)
			end
		end
	end,

	oncleansolution = function(sln)
		-- We don't generate anything for solutions, so there's nothing to clean.
	end,

	oncleanproject = function(prj)
		-- Need to clean one makefile per configuration
		for cfg in project.eachconfig(prj) do
			premake.clean.file(prj, p.modules.ndk.getMakefileName(prj, cfg, p.modules.ndk.MAKEFILE))

			if prj.kind == premake.WINDOWEDAPP then
				premake.clean.file(prj, p.modules.ndk.getMakefileName(prj, cfg, p.modules.ndk.APPMAKEFILE))
			end
		end
	end
}

--
-- Decide when the full module should be loaded.
--

return function(cfg)
	return (_ACTION == "ndk-makefile") or (_ACTION == "ndk-manifest")
end
