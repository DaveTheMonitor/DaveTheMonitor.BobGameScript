--#build
--#priority 999

local start_message = ""
if not is_mod_input_enabled then
    start_message = "Before you play BobGame, make sure you are flying, try to center the game as best as you can, and do not move your camera after you begin. This will help input handling.\n\n"
end

if is_mod_enabled then
    start_message = start_message .. "It is highly recommended to use the \"Enhanced Input\" option when playing on controller.\n\n"
else
    start_message = start_message .. "It is highly recommended to use the BobGame mod's \"Enhanced Input\" when playing on controller. You can find the mod on the Steam Workshop.\n\n"
end
start_message = start_message .. "It is highly recommended to disable day/night cycle, weather, clouds, and HUD when playing.\n\nBobGame is designed with Rupture HD in mind. Consider changing your texture pack to Rupture HD for the best experience."

msgbox("Welcome to BobGame!", start_message, "OK", "", "", "", true, false)

instance = BobGame.new()
Game.run(instance)