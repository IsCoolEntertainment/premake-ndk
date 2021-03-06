--
-- common.lua
-- Android exporter module for Premake - support code.
-- Copyright (c) 2014 Will Vale and the Premake project
--

local ndk       = premake.modules.ndk
local project   = premake.project

-- Constants
ndk.ANDROID     = 'android'
ndk.JNI         = 'jni'
ndk.MAKEFILE    = 'Android.mk'
ndk.APPMAKEFILE = 'Application.mk'
ndk.MANIFEST    = 'AndroidManifest.xml'
ndk.GLES30      = 'GLESv3'
ndk.GLES20      = 'GLESv2'
ndk.GLES10      = 'GLESv1_CM'
ndk.JAVA        = '.java'

-- Need to put makefiles in subdirectories by project configuration
function ndk.getProjectPath(this, cfg)
	-- e.g. c:/root/myconfig/myproject
	return path.join(this.location, cfg.buildcfg, this.name)
end

-- Is the given project valid for NDK builds?
function ndk.isValidProject(prj)
	-- Console apps don't make sense
	if prj.kind == premake.CONSOLEAPP then
		return false
	end

	return true
end

-- Extract API level from framework
function ndk.getApiLevel(cfg)
	if cfg.framework then
		local version, count = cfg.framework:gsub('android%-', '')
		if count == 1 then
			return tonumber(version)
		end
	end

	-- Unknown API level
	return 1
end
