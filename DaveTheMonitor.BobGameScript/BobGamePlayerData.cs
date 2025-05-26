using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Accessibility;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;
using NLua;
using StudioForge.Engine.Core;
using StudioForge.TotalMiner;
using StudioForge.TotalMiner.API;

namespace DaveTheMonitor.BobGameScript
{
    public sealed class BobGamePlayerData
    {
        private class EventInvoker
        {
            private struct Listener
            {
                public LuaFunction Func;
                public Lua Lua;
            }

            public int Count => _listeners.Count;
            private List<Listener> _listeners;

            public EventInvoker()
            {
                _listeners = new List<Listener>();
            }

            public void Invoke(Lua lua, params object[] args)
            {
                foreach (Listener listener in _listeners)
                {
                    if (listener.Lua == lua)
                    {
                        listener.Func.Call(args);
                    }
                }
            }

            public void Hook(LuaFunction func, Lua lua)
            {
                _listeners.Add(new Listener
                {
                    Func = func,
                    Lua = lua
                });
            }

            public void UnhookAll(Lua lua)
            {
                for (int i = _listeners.Count - 1; i >= 0; i--)
                {
                    if (_listeners[i].Lua == lua)
                    {
                        _listeners.RemoveAt(i);
                    }
                }
            }
        }

        private enum InputState
        {
            Down,
            Up
        }

        private struct InputEvent
        {
            public Buttons? Button;
            public Keys? Key;
            public InputState State;

            public InputEvent(Buttons button, InputState state)
            {
                Button = button;
                State = state;
            }

            public InputEvent(Keys key, InputState state)
            {
                Key = key;
                State = state;
            }
        }

        private object _semaphore;
        private List<InputEvent> _pendingInputEvents;
        private HashSet<Buttons> _pressedButtons;
        private EventInvoker[] _events;
        private ITMPlayer _player;

        public void Initialize(ITMPlayer player)
        {
            _semaphore = new object();
            _pendingInputEvents = new List<InputEvent>();
            _pressedButtons = new HashSet<Buttons>();
            _player = player;
            _events = new EventInvoker[5];
            for (int i = 0; i < _events.Length; i++)
            {
                _events[i] = new EventInvoker();
            }
        }

        public void KeyDown(InputKeyEventArgs e)
        {
            lock (_semaphore)
            {
                if (!_events.Any(e => e.Count > 0))
                {
                    return;
                }

                _pendingInputEvents.Add(new InputEvent(e.Key, InputState.Down));
            }
        }

        public void KeyUp(InputKeyEventArgs e)
        {
            lock (_semaphore)
            {
                if (!_events.Any(e => e.Count > 0))
                {
                    return;
                }

                _pendingInputEvents.Add(new InputEvent(e.Key, InputState.Up));
            }
        }

        public void HookEvent(ScriptEvent type, LuaFunction listener, Lua lua)
        {
            _events[(int)type].Hook(listener, lua);
        }

        public void UnhookEvent(ScriptEvent type, Lua lua)
        {
            _events[(int)type].UnhookAll(lua);
        }

        public void Pump(Lua lua)
        {
            lock (_semaphore)
            {
                try
                {
                    foreach (InputEvent e in _pendingInputEvents)
                    {
                        if (e.Key.HasValue)
                        {
                            EventInvoker invoker = e.State == InputState.Down ? _events[(int)ScriptEvent.KeyDown] : _events[(int)ScriptEvent.KeyUp];
                            invoker.Invoke(lua, (long)e.Key.Value);
                        }
                        else
                        {
                            EventInvoker invoker = e.State == InputState.Down ? _events[(int)ScriptEvent.ButtonDown] : _events[(int)ScriptEvent.ButtonUp];
                            invoker.Invoke(lua, (long)e.Button.Value);
                        }
                    }
                }
                catch (Exception e)
                {
                    BobGamePlugin.Instance._game.AddNotification("Failed to invoke events: " + e.Message);
                }
                _pendingInputEvents.Clear();
            }
        }

        public Vector2 GetGamepad()
        {
            return InputManager.GetGamepadLeftStick(_player.PlayerIndex);
        }

        public void Update()
        {
            lock (_semaphore)
            {
                UpdateControllerButton(Buttons.None);
                UpdateControllerButton(Buttons.DPadUp);
                UpdateControllerButton(Buttons.DPadDown);
                UpdateControllerButton(Buttons.DPadLeft);
                UpdateControllerButton(Buttons.DPadRight);
                UpdateControllerButton(Buttons.Start);
                UpdateControllerButton(Buttons.Back);
                UpdateControllerButton(Buttons.LeftStick);
                UpdateControllerButton(Buttons.RightStick);
                UpdateControllerButton(Buttons.LeftShoulder);
                UpdateControllerButton(Buttons.RightShoulder);
                UpdateControllerButton(Buttons.BigButton);
                UpdateControllerButton(Buttons.A);
                UpdateControllerButton(Buttons.B);
                UpdateControllerButton(Buttons.X);
                UpdateControllerButton(Buttons.Y);
                UpdateControllerButton(Buttons.RightTrigger);
                UpdateControllerButton(Buttons.LeftTrigger);
            }
        }

        private void UpdateControllerButton(Buttons button)
        {
            if (InputManager.IsButtonPressedNew(_player.PlayerIndex, button))
            {
                _pressedButtons.Add(button);
                _pendingInputEvents.Add(new InputEvent(button, InputState.Down));
            }
            else if (!InputManager.IsButtonPressed(_player.PlayerIndex, button))
            {
                if (_pressedButtons.Remove(button))
                {
                    _pendingInputEvents.Add(new InputEvent(button, InputState.Up));
                }
            }
        }
    }
}
