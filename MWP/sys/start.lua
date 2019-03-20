--[[

    ======================================================================
    ==================== STARTUP PROCEDURE FOR SKYNET ====================
    ======================================================================

    This file loads critical variables into the global table, clears cache
    variables that should not retain their values across program runs, and
    runs basic configuration procedures.

    23 August 2018
--]]

-- This variable is used by some files to determine whether the system is
-- running through start.lua or through some other means.
IS_LOADER = true

-- ===================== MODULE.LUA =====================
-- ============== /MWP/lib/core/module.lua ==============

-- Load the module library:
local module_loader = loadfile('/MWP/lib/core/module.lua')
setfenv(module_loader, getfenv())
ok, module = pcall(module_loader)
if not ok then print(module) else print('Module API loaded successfully.') end

-- Clear loaded libraries:
module.clear_module_cache()

-- ================= NOTYOURMOMSLUA.LUA =================
-- ========== /MWP/lib/core/notyourmomslua.lua ==========

nym = module.require('/MWP/lib/core/notyourmomslua.lua')

-- ===================== CLASS.LUA ======================
-- ============== /MWP/lib/core/class.lua ===============

Class = module.require('/MWP/lib/core/class.lua')

-- ================== PERSISTENCE.LUA ===================
-- =========== /MWP/lib/core/persistence.lua ============

pst = module.require('/MWP/lib/core/persistence.lua')
pst.initialize()

-- ====================== SKYNETRC =======================
-- ================= /MWP/sys/skynetrc ===================
-- All files specified in skynetrc will be executed here after all critical
-- libraries have been loaded.

ok, result = nym.run('/MWP/sys/skynetrc.lua')
if not ok then error(result) end
