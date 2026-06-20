-- smw.lua — per-monitor workspaces for Hyprland (AwesomeWM-style).
-- Each monitor gets its own independent 1..N workspaces, namespaced by a
-- 1-based monitor index: monitor 1 -> "m1:1".."m1:9", monitor 2 -> "m2:1".."m2:9".
-- The "m" prefix prevents waybar's std::stoi from misparsing the workspace ID
-- from the name (which causes duplicate buttons). Referenced via Hyprland's
-- `name:` prefix (e.g. focus "name:m2:3").
--
-- Inspired by / reimplemented from
-- https://github.com/zjeffer/split-monitor-workspaces (BSD-3-Clause,
-- zjeffer/Duckonaut), stripped to just disjoint per-monitor behavior.

local M = {}

local ws_per_monitor = 9
local monitor_prio   = {}  -- monitor.name -> 0-based priority

local function prefix(m)     return (monitor_prio[m.name] or 0) + 1 end
local function ws_name(m, n) return "m" .. prefix(m) .. ":" .. n end
local function ws_ref(m, n)  return "name:" .. ws_name(m, n) end

local function assign_priority(m)
    if m.is_mirror or monitor_prio[m.name] then return end
    local max = -1
    for _, p in pairs(monitor_prio) do
        if p > max then max = p end
    end
    monitor_prio[m.name] = max + 1
end

local function cur_mon()
    return hl.get_active_monitor() or hl.get_monitor_at_cursor()
end

-- Set persistent workspace rules for a monitor and optionally focus its first ws.
function M.map_monitor(m, focus_first)
    if m.is_mirror then return end
    for i = 1, ws_per_monitor do
        hl.workspace_rule({ workspace = ws_ref(m, i), persistent = true, monitor = m.name })
    end
    if focus_first ~= false then
        hl.dispatch(hl.dsp.focus({ workspace = ws_ref(m, 1) }))
        hl.dispatch(hl.dsp.workspace.move({ workspace = ws_ref(m, 1), monitor = m.name }))
    end
end

-- Snapshot each monitor's active workspace name for keep_focused restore.
local function snapshot()
    local saved, focused_id = {}, nil
    local active = hl.get_active_monitor()
    if active then focused_id = active.id end
    for _, m in ipairs(hl.get_monitors()) do
        local ws = hl.get_active_workspace(m)
        if ws then
            saved[m.id] = { monitor = m, name = ws.name, focused = (m.id == focused_id) }
        end
    end
    return saved
end

-- Full remap: reassign priorities, set rules on every monitor, then restore
-- each monitor's previous workspace so the view doesn't jump on config reload.
function M.remap_all()
    local saved = snapshot()
    monitor_prio = {}
    local monitors = hl.get_monitors()
    for _, m in ipairs(monitors) do assign_priority(m) end

    table.sort(monitors, function(a, b) return a.id < b.id end)
    local primary = monitors[1]
    for _, m in ipairs(monitors) do
        if m ~= primary then M.map_monitor(m) end
    end
    if primary then M.map_monitor(primary) end

    local restore_focused = nil
    for _, s in pairs(saved) do
        local want = "m" .. prefix(s.monitor) .. ":"
        if s.name:sub(1, #want) == want then
            if s.focused then
                restore_focused = s
            else
                local cur = hl.get_active_workspace(s.monitor)
                if not cur or cur.name ~= s.name then
                    hl.dispatch(hl.dsp.focus({ workspace = "name:" .. s.name }))
                end
            end
        end
    end
    if restore_focused then
        local cur = hl.get_active_workspace(restore_focused.monitor)
        if not cur or cur.name ~= restore_focused.name then
            hl.dispatch(hl.dsp.focus({ workspace = "name:" .. restore_focused.name }))
        end
    end
end

function M.setup()
    M.remap_all()
    hl.on("monitor.added",   function(m) assign_priority(m); M.map_monitor(m) end)
    hl.on("monitor.removed", function(m) monitor_prio[m.name] = nil end)
    hl.on("config.reloaded", function() M.remap_all() end)
end

-- Public dispatcher closures (compatible with hl.bind).

function M.workspace(n)
    return function()
        local m = cur_mon()
        if m then hl.dispatch(hl.dsp.focus({ workspace = ws_ref(m, n) })) end
    end
end

function M.move_silent(n)
    return function()
        local m = cur_mon()
        if m then
            hl.dispatch(hl.dsp.window.move({ workspace = ws_ref(m, n), follow = false }))
        end
    end
end

-- Move focus in a direction but never cross to another monitor.
function M.focus(direction)
    return function()
        local window = hl.get_active_window()
        local monitor = hl.get_active_monitor()
        hl.dispatch(hl.dsp.focus({ direction = direction }))
        local after = hl.get_active_monitor()
        if monitor and after and monitor.id ~= after.id and window then
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
    end
end

function M.cycle(dir)
    return function()
        local m = cur_mon()
        if not m or not m.active_workspace then return end
        local n = tonumber(m.active_workspace.name:match(":(%d+)$"))
        if not n then return end
        n = n + (dir == "next" and 1 or -1)
        if n > ws_per_monitor then n = 1
        elseif n < 1 then n = ws_per_monitor end
        hl.dispatch(hl.dsp.focus({ workspace = ws_ref(m, n) }))
    end
end

-- Move the active window to the active workspace on the next monitor and follow it.
function M.move_to_other_monitor()
    return function()
        local m = cur_mon()
        if not m then return end
        local monitors = hl.get_monitors()
        if #monitors < 2 then return end

        table.sort(monitors, function(a, b) return a.id < b.id end)
        local target = nil
        for i, mon in ipairs(monitors) do
            if mon.id == m.id then
                target = monitors[(i % #monitors) + 1]
                break
            end
        end
        if not target or not target.active_workspace then return end

        hl.dispatch(hl.dsp.window.move({ workspace = "name:" .. target.active_workspace.name }))
    end
end

-- Move all windows not on any mapped workspace to the current workspace.
-- Useful after first setup to collect windows left on old numbered workspaces.
function M.grab_rogue_windows()
    return function()
        local m = cur_mon()
        if not m then return end
        local cur_ws = hl.get_active_workspace(m)
        if not cur_ws then return end

        local mapped = {}
        for _, prio in pairs(monitor_prio) do
            for i = 1, ws_per_monitor do
                mapped["m" .. (prio + 1) .. ":" .. i] = true
            end
        end

        for _, window in ipairs(hl.get_windows()) do
            if window.mapped and window.workspace
               and not window.workspace.special
               and not mapped[window.workspace.name] then
                hl.dispatch(hl.dsp.window.move({
                    workspace = "name:" .. cur_ws.name,
                    window = window,
                    follow = false,
                }))
            end
        end
    end
end

return M
