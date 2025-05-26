using BobGameBuilder;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using SharpDX.X3DAudio;
using StudioForge.BlockWorld;
using StudioForge.Engine;
using StudioForge.Engine.Core;
using StudioForge.Engine.Game;
using StudioForge.TotalMiner;
using StudioForge.TotalMiner.API;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Rebar;

namespace DaveTheMonitor.BobGameScript
{
    public sealed class BobGamePlugin : ITMPlugin
    {
        public static BobGamePlugin Instance { get; private set; }
        public SwapChain SwapChain { get; private set; }
        private ITMMod _mod;
        internal ITMGame _game;
        private object _swapChainSemaphore = new object();
        private List<double> _frameTimes;
        private float _debugUpdateTimer;
        private float _debugUpdateFreq = 0.25f;
        private double _averageFrameTime;
        private double _minFrameTime;
        private double _maxFrameTime;
        private bool _profiling;
        private GameWithScreenManager _baseGame;
        private BobGamePlayerData _playerData;
        private Item _item;

        public BobGamePlayerData GetPlayerData(ITMPlayer player)
        {
            return _playerData;
        }

        public void Initialize(ITMPluginManager mgr, ITMMod mod)
        {
            _mod = mod;
            _item = (Item)mgr.Offsets.ItemID;
            Instance = this;
            _frameTimes = new List<double>();

            try
            {
                Type type = mod.GetType().Assembly.GetType("StudioForge.TotalMiner.TotalMinerGame");
                FieldInfo field = type.GetField("Instance", BindingFlags.Public | BindingFlags.Static);
                _baseGame = (GameWithScreenManager)field.GetValue(null);
                _baseGame.Window.KeyDown += KeyDown;
                _baseGame.Window.KeyUp += KeyUp;
            }
            catch
            {
                System.Windows.Forms.MessageBox.Show("Failed to get the game. Mod input will not work.", "Error", System.Windows.Forms.MessageBoxButtons.OK);
            }
        }

        private void KeyDown(object sender, InputKeyEventArgs e)
        {
            _playerData?.KeyDown(e);
        }

        private void KeyUp(object sender, InputKeyEventArgs e)
        {
            _playerData?.KeyUp(e);
        }

        public void InitializeGame(ITMGame game)
        {
            _game = game;
            game.AddEventItemSwing(_item, SwingBobGameItem);
        }

        private void SwingBobGameItem(Item item, ITMHand hand)
        {
            if (!hand.Owner.IsPlayer)
            {
                return;
            }

            BuildGame();
            SwapChain?.Dispose();
            SwapChain = null;
            _game.RunScript("bobgame\\game_lua", hand.Player);
        }

        public void ReportFrameTime(double time)
        {
            if (_profiling)
            {
                lock (_frameTimes)
                {
                    _frameTimes.Insert(0, time);
                    if (_frameTimes.Count > 60)
                    {
                        _frameTimes.RemoveAt(_frameTimes.Count - 1);
                    }
                }
            }
        }

        public void Callback(string data, GlobalPoint3D? p, ITMActor actor, ITMActor contextActor)
        {
            
        }

        public void Draw(ITMPlayer player, ITMPlayer virtualPlayer, Viewport vp)
        {
            lock (_swapChainSemaphore)
            {
                SwapChain?.Draw(player, virtualPlayer);
            }

            if (_profiling)
            {
                SpriteBatchSafe spriteBatch = CoreGlobals.SpriteBatch;
                spriteBatch.Begin();

                Vector2 pos = new Vector2(50, 200);
                spriteBatch.DrawString(CoreGlobals.GameFont16, $"Avg: {_averageFrameTime:0.000}", pos, Color.Yellow);
                pos.Y += 25;
                spriteBatch.DrawString(CoreGlobals.GameFont16, $"Min: {_minFrameTime:0.000}", pos, Color.Yellow);
                pos.Y += 25;
                spriteBatch.DrawString(CoreGlobals.GameFont16, $"Max: {_maxFrameTime:0.000}", pos, Color.Yellow);

                spriteBatch.End();
            }
        }

        public void InitializeSwapChain(GlobalPoint3D p, Point size)
        {
            lock (_swapChainSemaphore)
            {
                SwapChain?.Dispose();

                SwapChain = new SwapChain(CoreGlobals.GraphicsDevice, p, size, _game);
                for (int x = 0; x < size.X; x++)
                {
                    for (int y = 0; y < size.Y; y++)
                    {
                        SwapChain.BackBuffer.SetBlock(new Point(x, y), Block.ColorBlack);
                    }
                }
                SwapChain.BackBuffer.BuildVertices();
                SwapChain.Swap();
            }
        }

        public void DisposeSwapChain()
        {
            lock (_swapChainSemaphore)
            {
                SwapChain?.Dispose();
                SwapChain = null;
            }
        }

        public void Swap()
        {
            SwapChain?.Swap();
        }

        public bool HandleInput(ITMPlayer player)
        {
#if DEBUG
            if (InputManager.IsKeyPressedNew(player.PlayerIndex, Keys.F1))
            {
                BuildGame();
                return true;
            }
            else if (InputManager.IsKeyPressedNew(player.PlayerIndex, Keys.F2))
            {
                EndAllGames();
                return true;
            }
            else if (InputManager.IsKeyPressedNew(player.PlayerIndex, Keys.F3))
            {
                BuildGame();
                SwapChain?.Dispose();
                SwapChain = null;
                _game.RunScript("bobgame\\game_lua", player);
                return true;
            }
#endif
            return false;
        }

        private void EndAllGames()
        {
            Dictionary<string, long> history = _game.World.History.Table;
            List<string> historiesToClear = new List<string>();
            foreach (string key in history.Keys)
            {
                if (key.StartsWith("game_"))
                {
                    historiesToClear.Add(key);
                }
            }

            foreach (string key in historiesToClear)
            {
                _game.World.History.ClearHistory(key);
            }
        }

        private void BuildGame()
        {
            EndAllGames();

            _game.AddNotification("Building BobGame...");
            string path = Path.Combine(_mod.FullPath, "BobGameSource");
            ScriptBuild[] builds = new GameBuilder<Sprite>().Build(path);
            foreach (ScriptBuild build in builds)
            {
                WriteScript($"bobgame\\{build.Name}_lua", build.Code);
            }
            _game.AddNotification("BobGame Built!");
        }

        private void WriteScript(string name, string code)
        {
            Type scriptType = _game.GetType().Assembly.GetType("StudioForge.TotalMiner.Script", true);
            object script = scriptType.GetConstructor([typeof(string)]).Invoke([name]);
            List<string> commands = (List<string>)scriptType.GetField("Commands", BindingFlags.Public | BindingFlags.Instance).GetValue(script);
            commands.AddRange(code.Split('\n', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries));
            scriptType.GetField("IsChanged", BindingFlags.Public | BindingFlags.Instance).SetValue(script, true);
            _game.GetType().GetMethod("AddOrOverwriteScript", BindingFlags.Public | BindingFlags.Instance).Invoke(_game, [name, script, true]);
        }

        public void PlayerJoined(ITMPlayer player)
        {
            
        }

        public void PlayerLeft(ITMPlayer player)
        {
            
        }

        public object[] RegisterLuaFunctions(ITMScriptInstance si) => [new BobGameLua(this, _game, si)];

        public void UnloadMod()
        {
            EndAllGames();
            SwapChain?.Dispose();
            SwapChain = null;

            if (_baseGame != null)
            {
                _baseGame.Window.KeyDown -= KeyDown;
                _baseGame.Window.KeyUp -= KeyUp;
            }
        }

        public void Update()
        {
#if DEBUG
            _profiling = !_game.World.History.HasHistory("disable_profiling");
#else
            _profiling = false;
#endif


            if (_profiling)
            {
                lock (_frameTimes)
                {
                    if (_debugUpdateTimer > _debugUpdateFreq)
                    {
                        _debugUpdateTimer = 0;
                        _averageFrameTime = _frameTimes.Average();
                        _minFrameTime = _frameTimes.Min();
                        _maxFrameTime = _frameTimes.Max();
                    }
                }
                _debugUpdateTimer += Services.ElapsedTime;
            }
        }

        public void Update(ITMPlayer player)
        {
            if (_playerData == null)
            {
                _playerData = new BobGamePlayerData();
                _playerData.Initialize(player);
            }
            _playerData.Update();
        }

        public void WorldSaved(int version)
        {
            
        }
    }
}
