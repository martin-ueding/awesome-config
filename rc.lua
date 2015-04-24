-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
require("debian.menu")

require("vicious")

solarized = {
    red = '#dc322f',
    orange = '#cb4b16',
    yellow = '#b58900',
    magenta = '#d33682',
    violet = '#6c71c4',
    blue = '#268bd2',
    cyan = '#2aa198',
    green = '#859900',
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
    awesome.add_signal("debug::error", function (err)
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
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/mu/.config/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
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
tag_for_www = 9

assoc = {}
assoc[tag_for_www] = 'www'
assoc[tag_for_eml] = 'eml'
assoc[tag_for_im] = 'im'
assoc[tag_for_music] = 'pim'

tag_numbers = { 1, 2, 3, 4, 5, '6', '7', '8', '9', '0', '-', '=' }
tag_names = {}
for i = 1, #tag_numbers do
    tag_names[i] = tag_numbers[i]
    if assoc[i] ~= nil then
        tag_names[i] = tag_names[i] .. ":" .. assoc[i]
    end
end

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


-- {{{ Wibox

-- sunrise_widget = widget({ type = "textbox" })
-- sunrise_widget.text = wrap_with_color(awful.util.pread("sunrise"), 'blue')

spacer = widget({ type = "textbox" })
spacer.text = "    "

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

    return span .. vicious.helpers.format('$1 <b>$2%</b> $3', data) .. endspan
end

function if_active(data, iface)
    return data['{' .. iface .. ' up_kb}'] ~= nil and data['{' .. iface .. ' down_kb}'] ~= nil and data['{' .. iface .. ' up_kb}'] ~= '0.0' and data['{' .. iface .. ' down_kb}'] ~= '0.0'
end

function if_format(data, iface)
    return vicious.helpers.format(iface .. ': ${' .. iface .. ' down_kb} ↓ ${' .. iface .. ' up_kb} ↑ kB/s', data)
end

function net_widget_function(widget, data)
    local snippets = {}
    local ifaces = {'eth0', 'wlan0', 'vibr0'}

    for ignored, iface in pairs(ifaces) do
        if if_active(data, iface) then
            table.insert(snippets, if_format(data, iface))
        end
    end

    if #snippets > 0 then
        local result = table.concat(snippets, spacer.text)
        result = result .. spacer.text
        return wrap_with_color(result, 'blue')
    else
        return ''
    end
end

batwidget = widget({ type = "textbox" })
vicious.register(batwidget, vicious.widgets.bat, bat_func, 15, "BAT0")

netwidget = widget({ type = "textbox" })
vicious.register(netwidget, vicious.widgets.net, net_widget_function, 2)

mytextclock = widget({ type = "textbox" })
vicious.register(mytextclock, vicious.widgets.date, wrap_with_color("%a, %Y-%m-%d <b>%H:%M</b> %z", 'blue'), 10)

mysystray = widget({ type = "systray" })

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
                    awful.button({ }, 4, awful.tag.viewprev),
                    awful.button({ }, 5, awful.tag.viewnext)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
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
                                                  instance = awful.menu.clients({ width=250 })
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
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        spacer,
        mytextclock,
        spacer,
        batwidget,
        netwidget,
        spacer,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
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
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

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
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end)
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
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
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
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
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
            buttons = clientbuttons,
            callback = function(c)
                if c.class == "Xournal" then
                    c.screen = 2
                    c:tags({tags[c.screen][1]})
                else
                    c.screen = 1
                    c:tags({tags[c.screen][1]})
                end
            end
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
        rule = { class = "Firefox" },
        properties = { tag = tags[1][tag_for_www] }
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
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- os.execute('mu-startup &')

naughty.config.default_preset.timeout = 4

awful.screen.focus(1)

if screen.count() > 1 then
    awful.tag.setncol(2, tags[1][tag_for_eml])
    awful.tag.setmwfact(0.37, tags[1][tag_for_eml])
end
