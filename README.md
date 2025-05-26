# BobGame 2 Demo

BobGame is a 2D endless wave based survival mini-game for Total Miner. You must defeat hordes of enemies that get stronger the longer you survive. How long can you last?

Complete with three different weapons, multiple combos, and (possibly overtuned) endless enemy scaling. BobGame 2 allows the player to make full use of three completely unique weapons with different attacks and switch between them on the fly, even during combat to chain combos together.

The demo of BobGame 2 only has Goblins, but the full version will have more levels and enemies, including orcs, dryads, trolls, and (probably) more! To make up for the lack of enemy variety in the demo, the Goblins will quickly scale their health and speed as you complete waves. This scaling will be toned-down for the full game.

BobGame 2 runs entirely in a single lua script (with the exception of button inputs) in vanilla, using the world as a screen. However, this repository includes a mod that enhances it with the following improvements:

- Improved rendering: No screen tearing and smooth 60 FPS. The screen looks identical to how the vanilla screen would, since they both render using blocks.
- Input hooking: Gives the script direct access to keyboard and controller input, improving input consistency and removing all input delay. This especially improves movement on controller.
- View locking: The player's camera is locked to look at the game screen while playing so you don't have to center it manually.

I wanted the mod to be an optional quality of life improvement for BobGame 2, so the game can still run without the mod enabled, and nothing in terms of gameplay changes. Without the mod, it will run at 30 FPS by default (can be overridden, but 60 FPS is inconsistent due to mesh building delays), and uses ButtonEventScripts for some inputs.

When the full version releases, it will be pushed to this repository.

## Playing

You can play BobGame either by download the mod or by importing scripts.

### Mod

1. Download the mod from the Releases page.
2. Create a new flat world with default settings and enable the mod.
3. Swing the BobGame item in the "Other" tab of the item shop.

### Importing Scripts

1. Download the `Scripts.db` file.
2. Create a new flat world with default settings.
3. Import the scripts in the "Scripts" menu.
4. Run the `bobgame\game_lua` script.

It is highly recommended to use the mod's "Enhanced Input" setting when playing on controller.

It is recommended to disable day/night cycle, weather, clouds, and HUD for the best experience. Consider adjusting the screen distance in Options to suit your FOV before playing.

## Known Issues

Known issues in the Demo:

- Using the mod's "Enhanced Input" with buttons/keys that have other actions still performs the action (eg. pressing X on controller toggle fly mode).
- Vanilla input occasionally repeats movements inputs. This is most noticeable in menus.
- Canceling the script without clearing the handle history does not properly end the game.
- Pausing for less than 0.2 seconds causes the game to skip forward by the amount of time paused.
- Rebinding some controls to long button/key names can cause the button text to extend past the button area and possibly off-screen.
- Hot reloading the mod does not work.