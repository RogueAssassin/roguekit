# IDE setup for Rust (Oxide/Carbon) plugin projects

Goal: IntelliSense, navigation and a type-check build in Visual Studio, JetBrains Rider or VS Code, without shipping Facepunch's DLLs. The server still compiles the plugin at runtime; the IDE project is for development only.

## 1. Get the reference assemblies
1. Install the dedicated server with SteamCMD (Rust Dedicated Server app id `258550`) into a local test folder.
2. Install Oxide or Carbon into that folder following their current docs.
3. Copy these into `References/` next to your plugins (names can vary by build; copy what your plugin actually uses):
   - From `RustDedicated_Data/Managed/`: `Assembly-CSharp.dll`, `Assembly-CSharp-firstpass.dll`, `Facepunch.*.dll`, `Rust.*.dll`, `UnityEngine.*.dll` (at least `CoreModule`, `PhysicsModule`, `JSONSerializeModule`), `Newtonsoft.Json.dll`.
   - Oxide: `Oxide.Core.dll`, `Oxide.CSharp.dll`, `Oxide.Rust.dll`, `Oxide.Common.dll`.
   - Carbon: `Carbon.dll`, `Carbon.Common.dll`, `0Harmony.dll` (locations differ by Carbon version; check its docs).
4. Re-copy after every Rust or framework update, and note the build number in `References/README.txt`.

Do not commit these DLLs. They are not yours to redistribute.

## 2. Reference-only project (`RustPlugins.csproj`)
Adjust the target framework to whatever the referenced Oxide/Carbon assemblies require (commonly `net48`; if the IDE complains about framework mismatches, trust the framework's own docs).

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <LangVersion>latest</LangVersion>   <!-- IDE only. Keep code within what the server's compiler accepts. -->
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <OutputType>Library</OutputType>
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
    <OutputPath>bin\</OutputPath>
    <NoWarn>$(NoWarn);CS0649;CS0169;IDE0051</NoWarn> <!-- fields set by the framework, unused-private for hooks -->
  </PropertyGroup>

  <ItemGroup>
    <Compile Include="Oxide\**\*.cs" />
    <Compile Include="Carbon\**\*.cs" />
    <Compile Include="Shared\**\*.cs" />
  </ItemGroup>

  <ItemGroup>
    <Reference Include="References\*.dll" Exclude="References\0Harmony.dll">
      <Private>false</Private>
    </Reference>
  </ItemGroup>
</Project>
```

Notes:
- Hooks are discovered by name and are normally `private` and "unused" to the compiler, so suppress unused-member warnings for them rather than deleting them.
- If Oxide and Carbon plugins both live in one project, duplicate type names across files can clash because everything lives in one assembly. Split into two projects (one per framework) if they do.
- A `CS0246` here that the server does not show usually means a missing `References/` DLL, not broken code.

## 3. Suggested layout
```text
MyPlugins/
  RustPlugins.csproj
  .editorconfig
  .gitignore            # References/*.dll, bin/, obj/, .vs/, .idea/
  References/           # local only, plus README.txt with the Rust/framework build
  Oxide/MyPlugin.cs     # file name == class name
  Carbon/MyPlugin.cs
  Shared/               # optional, only if the framework allows shared sources
  docs/                 # hook notes, changelog
```
Oxide requires the **file name to match the plugin class name** (`MyPlugin.cs` contains `class MyPlugin`). A mismatch is a common cause of "plugin not loading".

## 4. Per-IDE notes
**Visual Studio**: open the `.csproj`. Use *Build* for a type-check. Set *Tools > Options > Text Editor > C# > Advanced* to show the analyzers you want. `Ctrl+Click` on game types opens decompiled metadata, which is the quickest way to verify a signature.

**JetBrains Rider**: open the folder or `.csproj`. Rider's decompiler (`F12` on a game type, then *Decompile*) shows `Assembly-CSharp` members. Enable *Settings > Editor > Code Style > C#* from `.editorconfig`.

**VS Code**: install the **C# Dev Kit** (or the C# extension), open the folder, and let it load `RustPlugins.csproj`. Minimal `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build",
      "type": "shell",
      "command": "dotnet build RustPlugins.csproj -nologo -v:minimal",
      "group": { "kind": "build", "isDefault": true },
      "problemMatcher": "$msCompile"
    }
  ]
}
```

**Claude Code in the IDE**: run `/ide` (or start Claude from the IDE's terminal) so it can see the open file, selection and diagnostics. Reference code with `@Oxide/MyPlugin.cs`, and select a hook before asking about it. The Claude Code `dotnet build` output uses the same `CSxxxx` codes as the IDE.

## 5. `.editorconfig` essentials
```ini
root = true
[*.cs]
indent_style = space
indent_size = 4
end_of_line = crlf
charset = utf-8
insert_final_newline = true
dotnet_style_qualification_for_fields = false
csharp_style_var_for_built_in_types = false
dotnet_diagnostic.IDE0051.severity = none   # unused private members: hooks
dotnet_diagnostic.IDE0060.severity = none   # unused parameters: hook signatures
```
Match the existing repo's line endings if it differs.

## 6. Local dev loop
1. Edit in the IDE. Run the build task for a type-check.
2. Copy (or symlink/watch) the `.cs` into the test server's plugin folder (`oxide/plugins` or `carbon/plugins`). Both frameworks hot-compile new or changed files.
3. Watch the server console/log for compile errors; they carry line numbers from the file.
4. Reload manually when needed. Command prefixes differ (`oxide.reload MyPlugin` / `o.reload` for Oxide, `c.reload MyPlugin` for Carbon); confirm with the framework's `help`.
5. Test with a real client or an automated bot only against a local/test server.

## 7. Common diagnostics
| Code | Typical cause here | Check first |
|---|---|---|
| `CS0246` type or namespace not found | Missing reference DLL or missing `using` | `References/`; the type's namespace in a decompiler |
| `CS1061` no definition for member | Member renamed or removed in this Rust build | Decompile the type; compare build numbers |
| `CS0115` / `CS0506` no suitable method to override | Wrong signature or base class | Hook docs; `RustPlugin` vs `CarbonPlugin` |
| `CS0029` / `CS0266` cannot convert | `NetworkableId`, `ulong`, `string` ID mismatches | Entity net ids and `UserIDString` usage |
| `CS8xxx`, `CS1056` newer-language errors | IDE accepts newer C# than the server compiler | Remove the feature or confirm the framework's supported level |
| `CS0649` field never assigned | Framework fills `[PluginReference]` fields | Suppress, do not delete |
| `IDE0051`/`IDE0060` | Hook methods flagged unused | Suppress |
| Plugin does not load, no error | File/class name mismatch, missing `[Info]`, or a namespace blocked by the framework | Filename, attributes, server log |
