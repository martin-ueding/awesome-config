-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local vicious = require("vicious")
vicious.helpers = require("vicious.helpers")

solarized = {
    red = '#dc322f',
    orange = '#cb4b16',
    yellow = '#b58900',
    magenta = '#d33682',
    violet = '#6c71c4',
    blue = '#268bd2',
    cyan = '#2aa198',
    green = '#859900',
    base01 = '#586e75',
    base02 = '#073642',
    base0 = '#839496',
    base1 = '#93a1a1',
}

span = {}

for color, hex in pairs(solarized) do
    span[color] = '<span color="' .. hex .. '">'
end

endspan = '</span>'

function wrap_with_color(string, color) 
    return span[color] .. string .. endspan
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.get().wallpaper = "/home/mu/.config/wallpaper.jpg"

-- This is used later as the default terminal and editor to run.
terminal = "konsole"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier
}

default_layout = awful.layout.suit.tile

tag_for_eml = 10
tag_for_im = 12
tag_for_music = 11
tag_for_queue = 8
tag_for_www = 9

tag_numbers = { 1, 2, 3, 4, 5, '6', '7', '8', '9', '0', '-', '=' }
tag_names = tag_numbers

tags = {}
tags[1] = awful.tag(
    tag_names,
    s,
    { default_layout, default_layout, default_layout, default_layout,
    default_layout, default_layout, default_layout, awful.layout.suit.fair,
    default_layout, default_layout, awful.layout.suit.max, awful.layout.suit.fair }
)
for s = 2, screen.count() do
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, default_layout)
end

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}


-- {{{ Wibox

-- sunrise_widget = widget({ type = "textbox" })
-- sunrise_widget.text = wrap_with_color(awful.util.pread("sunrise"), 'blue')

spacer = "   "

function bat_func(widget, data)
    local state = data[1]
    local percentage = tonumber(data[2])
    local time = data[2]
    local color
    local span

    if percentage > 30 or state ~= '-' then
        span = '<span color="' .. solarized.green .. '">'
    elseif percentage > 10 then
        span = '<span color="black" bgcolor="' .. solarized.yellow .. '">'
    else
        span = '<span color="black" bgcolor="' .. solarized.red .. '">'
    end

    return span .. vicious.helpers.format('$1 <b>$2%</b> $3', data) .. endspan .. spacer
end

function if_exists(data, iface)
    return data['{' .. iface .. ' up_kb}'] ~= nil and data['{' .. iface .. ' down_kb}'] ~= nil
end

function if_active(data, iface)
    return data['{' .. iface .. ' up_kb}'] ~= '0.0' or data['{' .. iface .. ' down_kb}'] ~= '0.0'
end

function if_format(data, iface)
    local string = vicious.helpers.format(iface .. ': ${' .. iface .. ' down_kb} ↓ ${' .. iface .. ' up_kb} ↑ kB/s', data)
    if if_active(data, iface) then
        return wrap_with_color(string, 'blue')
    else
        return wrap_with_color(string, 'base01')
    end
end

last_shown = nil

function net_widget_function(widget, data)
    local snippets = {}
    local ifaces = {'eth0', 'wlan0', 'vibr0'}

    -- Compile a list of active interfaces
    local active_ifaces = {}
    for ignored, iface in pairs(ifaces) do
        if if_exists(data, iface) and if_active(data, iface) then
            table.insert(active_ifaces, iface)
        end
    end

    local to_show = ''
    if last_shown ~= nil and if_active(data, last_shown) then
        to_show = last_shown
    elseif #active_ifaces > 0 then
        to_show = active_ifaces[1]
    else
        to_show = ifaces[1]
    end
    last_shown = to_show

    if to_show ~= nil then
        return if_format(data, to_show) .. spacer
    else
        return ''
    end
end

function dio_exists(data, dev)
    return data['{' .. dev .. ' read_mb}'] ~= nil and data['{' .. dev .. ' write_mb}'] ~= nil
end

function dio_active(data, dev)
    return data['{' .. dev .. ' read_mb}'] ~= '0.0' or data['{' .. dev .. ' write_mb}'] ~= '0.0'
end

function dio_format(data, dev)
    local string = vicious.helpers.format(dev .. ': ${' .. dev .. ' write_mb} ↓ ${' .. dev .. ' read_mb} ↑ MB/s', data)
    if dio_active(data, dev) then
        return wrap_with_color(string, 'cyan')
    else
        return wrap_with_color(string, 'base01')
    end
end

function dio_widget_function(widget, data)
    local snippets = {}
    local devs = {'sda', 'sdc', 'sdd'}

    for ignored, dev in pairs(devs) do
        if dio_exists(data, dev) then
            table.insert(snippets, dio_format(data, dev))
        end
    end

    if #snippets > 0 then
        local result = table.concat(snippets, spacer)
        return result .. spacer
    else
        return ''
    end
end

function widget_printer(entity, format, index, limit_show, limit_bad, limit_critical)
    function formatter(widget, data)
        local snippets = {}
        local indicator = tonumber(data[index])
        local span

        if indicator >= limit_critical then
            span = '<span color="black" bgcolor="' .. solarized.red .. '">'
        elseif indicator >= limit_bad then
            span = '<span color="black" bgcolor="' .. solarized.orange .. '">'
        elseif indicator >= limit_show then
            span = '<span color="' .. solarized.yellow .. '">'
        else
            span = '<span color="' .. solarized.base01 .. '">'
        end

        table.insert(snippets, span)
        table.insert(snippets, entity .. ': ')
        table.insert(snippets, vicious.helpers.format(format, data))
        table.insert(snippets, '</span>')
        table.insert(snippets, spacer)
        local result = table.concat(snippets, '')
        return result
    end

    return formatter
end

batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat, bat_func, 15, "BAT0")

netwidget = wibox.widget.textbox()
vicious.register(netwidget, vicious.widgets.net, net_widget_function, 2)

diowidget = wibox.widget.textbox()
vicious.register(diowidget, vicious.widgets.dio, dio_widget_function, 2)

cpuwidget = wibox.widget.textbox()
vicious.register(cpuwidget, vicious.widgets.cpu, widget_printer('CPU', '$1 %', 1, 20, 90, 101), 2)

memwidget = wibox.widget.textbox()
vicious.register(memwidget, vicious.widgets.mem, widget_printer('RAM', '$2 / $3 MB', 1, 75, 85, 95), 5)

mytextclock = wibox.widget.textbox()
vicious.register(mytextclock, vicious.widgets.date, wrap_with_color("%a, %Y-%m-%d <b>%H:%M</b> %z" .. spacer, 'blue'), 10)

mysystray = wibox.widget.systray()
-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
-- mykeyboardlayout = wibox.widget.keyboardlayout()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 5, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 4, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(awful.layout.layouts,  1, mouse.screen) end),
                           awful.button({ }, 3, function () awful.layout.inc(awful.layout.layouts, -1, mouse.screen) end),
                           awful.button({ }, 4, function () awful.layout.inc(awful.layout.layouts,  1, mouse.screen) end),
                           awful.button({ }, 5, function () awful.layout.inc(awful.layout.layouts, -1, mouse.screen) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(cpuwidget)
    right_layout:add(memwidget)
    right_layout:add(diowidget)
    right_layout:add(netwidget)
    right_layout:add(batwidget)

    right_layout:add(mytextclock)
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey, }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift" }, "q", awesome.quit),

    awful.key({ modkey, }, "l", function () awful.tag.incmwfact( 0.05) end),
    awful.key({ modkey, }, "h", function () awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1) end),
    awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1) end),
    awful.key({ modkey, "Control" }, "h", function () awful.tag.incncol( 1) end),
    awful.key({ modkey, "Control" }, "l", function () awful.tag.incncol(-1) end),
    awful.key({ modkey, }, "space", function () awful.layout.inc(awful.layout.layouts, 1, mouse.screen) end),
    awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(awful.layout.layouts, -1, mouse.screen) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "d", function () awful.util.spawn("dolphin") end),
    awful.key({ modkey }, "s", function () awful.util.spawn("dolphin Dokumente/Studium/Master_Science_Physik/") end),
    awful.key({ modkey }, "F2", function () awful.util.spawn("suspend-hook") end),
    awful.key({ modkey }, "F1", function () awful.util.spawn("xbacklight - 10") end),
    awful.key({ modkey }, "F2", function () awful.util.spawn("xbacklight + 10") end),
    awful.key({ modkey, "Shift" }, "x", function () awful.util.spawn("xournal") end),
    awful.key({ }, "XF86TaskPane", function () awful.util.spawn("thinkpad-rotate") end),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),
    awful.key({"Control", "Shift", "Alt"}, "PageDown", function () awful.util.spawn_with_shell("systemctl poweroff") end)
)

function wrapped_kill(client)
    if client.class == 'Plasma' then
        return
    end

    client:kill()
end

function wrapped_fullscreen(client)
    if client.class == 'Plasma' then
        return
    end

    client.fullscreen = not client.fullscreen
end

function wrapped_minimize(client)
    if client.class == 'Plasma' then
        return
    end

    -- The client currently has the input focus, so it cannot be
    -- minimized, since minimized clients can't have the focus.
    client.minimized = true
end

function wrapped_maximize(client)
    if client.class == 'Plasma' then
        return
    end

    client.maximized_horizontal = not client.maximized_horizontal
    client.maximized_vertical   = not client.maximized_vertical
end

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      wrapped_fullscreen),
    awful.key({ modkey,           }, "c",      wrapped_kill),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n", wrapped_minimize),
    awful.key({ modkey,           }, "m", wrapped_maximize)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(12, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = true,
            keys = clientkeys,
            maximized_vertical = false,
            maximized_horizontal = false,
            buttons = clientbuttons
        }
    },
    {
        rule = { class = "pinentry" },
        properties = { floating = true }
    },
    {
        rule = { class = "gimp" },
        properties = { floating = true }
    },
    {
        rule = { class = "Klipper" },
        properties = { floating = true }
    },
    {
        rule = { class = "Plasma-desktop" },
        properties = { floating = true },
        callback = function(c)
            c:geometry( { width = 600 , height = 500 } )
        end,
    },
    {
        rule = { class = "plasmashell", name = "Arbeitsfläche — Plasma" },
        properties = { minimized = true, focusable = false, tag= tags[12] },
    },
    {
        rule = { class = "Firefox" },
        properties = { tag = tags[1][tag_for_www] }
    },
    {
        rule = { class = "Chromium-browser" },
        properties = { tag = tags[1][tag_for_music] }
    },
    {
        rule = { class = "Rekonq" },
        properties = { tag = tags[1][tag_for_www] }
    },
    {
        rule = { class = "Skype" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Mumble" },
        properties = { tag = tags[1][tag_for_im] }
    },
--    {
--        rule = { class = "Keepassx", type = "normal" },
--        properties = { tag = tags[1][tag_for_www], minimized = true }
--    },
    {
        rule = { class = "Kopete" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Pidgin" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Ekiga" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Empathy" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Linphone" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Sflphone-client-kde" },
        properties = { tag = tags[1][tag_for_im] }
    },
    {
        rule = { class = "Clementine" },
        properties = { tag = tags[1][tag_for_music] }
    },
    {
        rule = { class = "Thunderbird" },
        properties = { tag = tags[1][tag_for_eml] }
    },
    {
        rule = { class = "Ktorrent" },
        properties = { tag = tags[1][tag_for_queue] }
    },
    {
        rule = { class = "Kontact" },
        properties = { tag = tags[1][tag_for_music] }
    },
    {
        rule = { class = "Dolphin", name = "Kopiervorgang" },
        properties = { floating = true }
    },
    {
        rule = { class = "Dolphin", name = "Verschiebevorgang" },
        properties = { floating = true }
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    if not awesome.startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    elseif not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count change
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

-- Enable sloppy focus
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- naughty.config.default_preset.timeout = 4

awful.screen.focus(1)

if screen.count() > 1 then
    awful.tag.setncol(2, tags[1][tag_for_eml])
    awful.tag.setmwfact(0.37, tags[1][tag_for_eml])
end

awful.util.spawn_with_shell("mu-startup")
