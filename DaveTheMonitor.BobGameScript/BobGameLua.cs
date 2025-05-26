using Microsoft.Xna.Framework;
using NLua;
using SharpDX.X3DAudio;
using StudioForge.BlockWorld;
using StudioForge.Engine.Core;
using StudioForge.Engine.GamerServices;
using StudioForge.TotalMiner;
using StudioForge.TotalMiner.API;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

#pragma warning disable IDE1006 // Naming Styles

namespace DaveTheMonitor.BobGameScript
{
    public sealed class BobGameLua
    {
        private ITMGame _game;
        private ITMScriptInstance _si;
        private Lua _lua;
        private BobGamePlugin _plugin;

        public BobGameLua(BobGamePlugin plugin, ITMGame game, ITMScriptInstance si)
        {
            _game = game;
            _si = si;
            _plugin = plugin;
        }

        private Lua GetLua()
        {
            if (_lua != null)
            {
                return _lua;
            }

            FieldInfo siLua = _si.GetType().GetField("Lua", BindingFlags.Public | BindingFlags.Instance);
            object luaInstance = siLua.GetValue(_si);
            FieldInfo luaLua = luaInstance.GetType().GetField("Lua", BindingFlags.Public | BindingFlags.Instance);
            _lua = (Lua)luaLua.GetValue(luaInstance);
            return _lua;
        }

        [LuaFuncRegister]
        public bool bobgame_is_input_enabled()
        {
            return true;
        }

        [LuaFuncRegister]
        public void bobgame_hook_event(long @event, LuaFunction listener)
        {
            BobGamePlayerData data = _plugin.GetPlayerData(_si.Player);
            data.HookEvent((ScriptEvent)@event, listener, GetLua());
        }

        [LuaFuncRegister]
        public void bobgame_unhook_event(long @event)
        {
            BobGamePlayerData data = _plugin.GetPlayerData(_si.Player);
            data.UnhookEvent((ScriptEvent)@event, GetLua());
        }

        [LuaFuncRegister]
        public void bobgame_unhook_all()
        {
            Lua lua = GetLua();
            BobGamePlayerData data = _plugin.GetPlayerData(_si.Player);
            data.UnhookEvent(ScriptEvent.KeyUp, lua);
            data.UnhookEvent(ScriptEvent.KeyDown, lua);
            data.UnhookEvent(ScriptEvent.ButtonUp, lua);
            data.UnhookEvent(ScriptEvent.ButtonDown, lua);
        }

        [LuaFuncRegister]
        public void bobgame_pump_events()
        {
            _plugin.GetPlayerData(_si.Player).Pump(GetLua());
        }

        [LuaFuncRegister]
        public void bobgame_get_gamepad(out double x, out double y)
        {
            Vector2 gamepad = _plugin.GetPlayerData(_si.Player).GetGamepad();
            x = gamepad.X;
            y = gamepad.Y;
        }

        [LuaFuncRegister]
        public void bobgame_set_input(bool enabled)
        {
            _si.Player.OverrideControlInput = !enabled;
        }

        [LuaFuncRegister]
        public void bobgame_set_view_dir(double x, double y, double z)
        {
            Vector3 v = new Vector3((float)x, (float)y, (float)z);
            v.Normalize();
            _si.Player.ViewDirection = v;
        }

        [LuaFuncRegister]
        public void bobgame_set_flying()
        {
            _si.Player.FlyMode = FlyMode.Slow;
        }

        [LuaFuncRegister]
        public bool bobgame_is_swap_chain_enabled()
        {
            return true;
        }

        [LuaFuncRegister]
        public void bobgame_initialize_swap_chain(long x, long y, long z, long size_x, long size_y)
        {
            BobGamePlugin.Instance.InitializeSwapChain(new GlobalPoint3D((int)x, (int)y, (int)z), new Point((int)size_x, (int)size_y));
        }

        [LuaFuncRegister]
        public void bobgame_swap_chain_set_pixel(long x, long y, long block)
        {
            BobGamePlugin.Instance.SwapChain?.BackBuffer.SetBlock(new Point((int)x, (int)y), (Block)block);
        }

        [LuaFuncRegister]
        public void bobgame_swap_chain_present()
        {
            BobGamePlugin.Instance.SwapChain?.BackBuffer.BuildVertices();
            BobGamePlugin.Instance.Swap();
        }

        [LuaFuncRegister]
        public void bobgame_swap_chain_dispose()
        {
            BobGamePlugin.Instance.DisposeSwapChain();
        }

        [LuaFuncRegister]
        public bool bobgame_is_profiling_enabled()
        {
#if DEBUG
            return true;
#else
            return false;
#endif
        }

        [LuaFuncRegister]
        public void bobgame_report_time(double time)
        {
            BobGamePlugin.Instance.ReportFrameTime(time);
        }
    }
}

#pragma warning restore IDE1006 // Naming Styles
