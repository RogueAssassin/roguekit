# Plugin skeletons

Minimal, conservative starting points. Verify every hook signature and API name against the target Rust build and framework version before relying on it.

## Oxide / uMod (`Oxide/MyPlugin.cs`)
```csharp
using System.Collections.Generic;
using Newtonsoft.Json;

namespace Oxide.Plugins
{
    [Info("MyPlugin", "AuthorName", "1.0.0")]
    [Description("One sentence describing what this does.")]
    public class MyPlugin : RustPlugin
    {
        private const string UsePermission = "myplugin.use";

        private Configuration _config;

        private void Init()
        {
            permission.RegisterPermission(UsePermission, this);
        }

        private void Unload()
        {
            // Destroy UI, timers, spawned entities, components; save data.
        }

        [ChatCommand("hello")]
        private void CmdHello(BasePlayer player, string command, string[] args)
        {
            if (!permission.UserHasPermission(player.UserIDString, UsePermission))
            {
                Reply(player, "NoPermission");
                return;
            }

            Reply(player, "Hello", player.displayName);
        }

        #region Config
        private class Configuration
        {
            [JsonProperty("Config version")]
            public string Version = "1.0.0";
        }

        protected override void LoadDefaultConfig() => _config = new Configuration();

        protected override void LoadConfig()
        {
            base.LoadConfig();
            try
            {
                _config = Config.ReadObject<Configuration>();
                if (_config == null) throw new System.Exception("empty config");
            }
            catch
            {
                PrintWarning("Config invalid, using defaults (file left untouched).");
                LoadDefaultConfig();
            }
        }

        protected override void SaveConfig() => Config.WriteObject(_config, true);
        #endregion

        #region Lang
        protected override void LoadDefaultMessages()
        {
            lang.RegisterMessages(new Dictionary<string, string>
            {
                ["NoPermission"] = "You do not have permission to use this.",
                ["Hello"] = "Hello, {0}!",
            }, this);
        }

        private void Reply(BasePlayer player, string key, params object[] args) =>
            player.ChatMessage(string.Format(lang.GetMessage(key, this, player.UserIDString), args));
        #endregion
    }
}
```
Checks: the file is `MyPlugin.cs`; the class name equals the file name; hooks stay `private` unless the framework requires otherwise; `Unload` is idempotent.

## Carbon-native (`Carbon/MyPlugin.cs`)
Carbon plugins use the `Carbon.Plugins` namespace and `CarbonPlugin`, and may use newer C# syntax within the level your Carbon build supports.
```csharp
using Carbon.Plugins;   // verify against your Carbon version
using Oxide.Plugins;    // Info/Description attributes and Oxide-compatible APIs live here in Carbon's layer

namespace Carbon.Plugins
{
    [Info("MyPlugin", "AuthorName", "1.0.0")]
    [Description("One sentence describing what this does.")]
    public class MyPlugin : CarbonPlugin
    {
        private void OnServerInitialized(bool initial)
        {
            Puts("Loaded.");
        }

        private void Unload()
        {
            // Same lifecycle duties as Oxide, plus Harmony cleanup below.
        }
    }
}
```
Confirm the exact namespaces, base class and hook attribute names in the Carbon documentation for your version before extending this; do not copy them from memory.

### Harmony patches (Carbon)
Use Harmony only when no hook exists. Rules:
- Patch the narrowest method possible, prefer `Prefix`/`Postfix` over `Transpiler`, and keep patch bodies allocation-free.
- Every patch must be removable: unpatch on `Unload` (Harmony instance `UnpatchSelf()` or by ID), or the patch survives the reload and stacks.
- Guard against Rust updates changing the target: resolve methods by name with `AccessTools`, log and disable the feature if resolution fails, never throw into game code.
- A bad prefix can crash the server tick. Test on a local server and keep a one-line way to disable the patch (config flag).

## One file for both frameworks
Use conditional compilation only for the minimum that differs. Confirm which symbols your Carbon and Oxide builds define (Carbon defines its own; check its docs) before relying on them.
```csharp
#if CARBON
namespace Carbon.Plugins { public class MyPlugin : CarbonPlugin { /* ... */ } }
#else
namespace Oxide.Plugins { public class MyPlugin : RustPlugin { /* ... */ } }
#endif
```
Prefer a shared logic class in a separate file only if the framework supports multi-file plugins. Otherwise keep one file and isolate framework-specific code in clearly marked `#region`s.

## Plugin metadata comments
Oxide-style compile directives live in comments at the top of the file, for example plugin dependencies and extra assembly references. Check the framework docs for exact syntax, and keep dependencies optional (null-check `[PluginReference]` fields) unless the plugin cannot work without them.
