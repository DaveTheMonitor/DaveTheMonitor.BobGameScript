--#build
--#priority 001

---@diagnostic disable: undefined-global

-- BobGame2 has a complementary mod that improves performance and controls.
-- The game still works without the mod, but using it mod will make the game
-- feel better to play (ie. less input delay)
-- The mod provides the following, which can all be disabled separately:
-- 1. Direct access to button event inputs. This reduces input delay as the game doesn't
--    need to queue a script when the button is pressed. This also allows it to work much
--    better on controller than using vanilla controls.
--    Can be disabled with "disable_input" history.
-- 2. Swap Chain Rendering. This allows the game to draw a frame instantly without
--    waiting for the chunk loader. This reduces screen tearing and input delay.
--    This method of rendering does not set any blocks, while vanilla rendering does.
--    This method still uses block textures, so the actual render result looks almost
--    identical to vanilla.
--    Note that this method of rendering locks the FPS to the time required to render
--    a frame. Vanilla rendering does not since the chunk loader runs on a separate
--    thread. This also means reported frame times will be much higher with this
--    rendering method. If you are having issues with performance, try disabling this.
--    Can be disabled with "disable_swap_chain" history.
-- 3. Profiling. Reports framerate times.
--    Can be disabled with "disable_profiling" history.

---@enum mod_event
ModEvent = {
    key_up = 1,
    key_down = 2,
    button_up = 3,
    button_down = 4
}

---@enum keys
Keys = {
    none = 0,
    back = 8,
    tab = 9,
    enter = 13,
    caps_lock = 20,
    escape = 27,
    space = 32,
    page_up = 33,
    page_down = 34,
    -- can't name "end" because of end keyword
    end_key = 35,
    home = 36,
    left = 37,
    up = 38,
    right = 39,
    down = 40,
    select = 41,
    print = 42,
    execute = 43,
    print_screen = 44,
    insert = 45,
    delete = 46,
    help = 47,
    d0 = 48,
    d1 = 49,
    d2 = 50,
    d3 = 51,
    d4 = 52,
    d5 = 53,
    d6 = 54,
    d7 = 55,
    d8 = 56,
    d9 = 57,
    a = 65,
    b = 66,
    c = 67,
    d = 68,
    e = 69,
    f = 70,
    g = 71,
    h = 72,
    i = 73,
    j = 74,
    k = 75,
    l = 76,
    m = 77,
    n = 78,
    o = 79,
    p = 80,
    q = 81,
    r = 82,
    s = 83,
    t = 84,
    u = 85,
    v = 86,
    w = 87,
    x = 88,
    y = 89,
    z = 90,
    left_windows = 91,
    right_windows = 92,
    apps = 93,
    sleep = 95,
    num_pad0 = 96,
    num_pad1 = 97,
    num_pad2 = 98,
    num_pad3 = 99,
    num_pad4 = 100,
    num_pad5 = 101,
    num_pad6 = 102,
    num_pad7 = 103,
    num_pad8 = 104,
    num_pad9 = 105,
    multiply = 106,
    add = 107,
    separator = 108,
    subtract = 109,
    decimal = 110,
    divide = 111,
    f1 = 112,
    f2 = 113,
    f3 = 114,
    f4 = 115,
    f5 = 116,
    f6 = 117,
    f7 = 118,
    f8 = 119,
    f9 = 120,
    f10 = 121,
    f11 = 122,
    f12 = 123,
    f13 = 124,
    f14 = 125,
    f15 = 126,
    f16 = 127,
    f17 = 128,
    f18 = 129,
    f19 = 130,
    f20 = 131,
    f21 = 132,
    f22 = 133,
    f23 = 134,
    f24 = 135,
    num_lock = 144,
    scroll = 145,
    left_shift = 160,
    right_shift = 161,
    left_control = 162,
    right_control = 163,
    left_alt = 164,
    right_alt = 165,
    browser_back = 166,
    browser_forward = 167,
    browser_refresh = 168,
    browser_stop = 169,
    browser_search = 170,
    browser_favorites = 171,
    browser_home = 172,
    volume_mute = 173,
    volume_down = 174,
    volume_up = 175,
    media_next_track = 176,
    media_previous_track = 177,
    mediastop = 178,
    media_play_pause = 179,
    launch_mail = 180,
    select_media = 181,
    launch_application1 = 182,
    launch_application2 = 183,
    oem_semicolon = 186,
    oem_plus = 187,
    oem_comma = 188,
    oem_minus = 189,
    oem_period = 190,
    oem_question = 191,
    oem_tilde = 192,
    oem_open_brackets = 219,
    oem_pipe = 220,
    oem_close_brackets = 221,
    oem_quotes = 222,
    oem_8 = 223,
    oem_backslash = 226,
    process_key = 229,
    attn = 246,
    crsel = 247,
    exsel = 248,
    erase_eof = 249,
    play = 250,
    zoom = 251,
    pa1 = 253,
    oem_clear = 254,
    chat_pad_green = 202,
    chat_pad_orange = 203,
    pause = 19,
    ime_convert = 28,
    ime_no_convert = 29,
    kana = 21,
    kanji = 25,
    oem_auto = 243,
    oem_copy = 242,
    oem_enl_w = 244
}

---@enum buttons
Buttons = {
    none = 0,
    dpad_up = 1,
    dpad_down = 2,
    dpad_left = 4,
    dpad_right = 8,
    start = 0x10,
    back = 0x20,
    left_stick = 0x40,
    right_stick = 0x80,
    left_shoulder = 0x100,
    right_shoulder = 0x200,
    big_button = 0x800,
    a = 0x1000,
    b = 0x2000,
    x = 0x4000,
    y = 0x8000,
    right_trigger = 0x400000,
    left_trigger = 0x800000
}

is_mod_enabled = bobgame_is_input_enabled ~= nil

if bobgame_is_input_enabled ~= nil then
    is_mod_input_enabled = bobgame_is_input_enabled() and get_history("bobgame\\disable_input") == 0
else
    is_mod_input_enabled = false
end

if bobgame_is_swap_chain_enabled ~= nil then
    is_mod_swap_chain_enabled = bobgame_is_swap_chain_enabled() and get_history("bobgame\\disable_swap_chain") == 0
else
    is_mod_swap_chain_enabled = false
end

if bobgame_is_profiling_enabled ~= nil then
    is_mod_profiling_enabled = bobgame_is_profiling_enabled() and get_history("bobgame\\disable_profiling") == 0
else
    is_mod_profiling_enabled = false
end

---@param input boolean
function set_input(input)
    if is_mod_input_enabled then
        bobgame_set_input(input)
    end
end

---@param event mod_event
---@param listener function
function hook_event(event, listener)
    if is_mod_input_enabled then
        bobgame_hook_event(event, listener)
    end
end

---@param event mod_event
function unhook_event(event)
    if is_mod_input_enabled then
        bobgame_unhook_event(event)
    end
end

function unhook_all()
    if is_mod_input_enabled then
        bobgame_unhook_all()
    end
end

---@return number x
---@return number y
function get_gamepad()
    if is_mod_input_enabled then
        return bobgame_get_gamepad()
    end
    return 0, 0
end

function pump_mod_events()
    if is_mod_input_enabled then
        bobgame_pump_events()
    end
end

---@param x number
---@param y number
---@param z number
function set_view_dir(x, y, z)
    if is_mod_input_enabled then
        bobgame_set_view_dir(x, y, z)
    end
end

function set_flying()
    if is_mod_input_enabled then
        bobgame_set_flying()
    end
end

---@param x integer
---@param y integer
---@param z integer
---@param width integer
---@param height integer
function initialize_swap_chain(x, y, z, width, height)
    if is_mod_swap_chain_enabled then
        bobgame_initialize_swap_chain(x, y, z, width, height)
    end
end

---@param x integer
---@param y integer
---@param block integer
function swap_chain_set_pixel(x, y, block)
    if is_mod_swap_chain_enabled then
        bobgame_swap_chain_set_pixel(x, y, block)
    end
end

function swap_chain_present()
    if is_mod_swap_chain_enabled then
        bobgame_swap_chain_present()
    end
end

function swap_chain_dispose()
    if is_mod_swap_chain_enabled then
        bobgame_swap_chain_dispose()
    end
end

---@param time number
function report_frame_time(time)
    if is_mod_profiling_enabled then
        bobgame_report_time(time)
    end
end