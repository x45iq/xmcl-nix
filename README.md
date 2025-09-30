# xmcl-nix

**X Minecraft Launcher (XMCL)** — современный лаунчер для Minecraft, упакованный для Nix и Home Manager.
Этот флейк позволяет установить и запускать [XMCL](https://github.com/Voxelum/x-minecraft-launcher) на NixOS и других системах с Nix.

---

## ✨ Возможности
- Пакет `xmcl` с необходимыми runtime-зависимостями.
- Поддержка дополнительных аргументов командной строки.
- Возможность указать свои JRE, которые автоматически подхватываются XMCL.
- Модуль Home Manager для удобной интеграции.

---

## 🚀 Установка

### Через `nix run`
```bash
nix run github:x45iq/xmcl-nix
````

### Добавление в `flake.nix`

```nix
{
  inputs = {
    xmcl.url = "github:x45iq/xmcl-nix";
  };

  outputs = { self, xmcl, ... }: {
    packages.x86_64-linux.my-xmcl = xmcl.packages.x86_64-linux.default;
  };
}
```

### Home Manager модуль

```nix
{
  inputs = {
    xmcl.url = "github:x45iq/xmcl-nix";
  };

  outputs = { self, nixpkgs, xmcl, ... }: {
    homeConfigurations.my-user = nixpkgs.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        xmcl.homeModules.xmcl
        {
          programs.xmcl = {
            enable = true;
            commandLineArgs = [
              "--enable-features=UseOzonePlatform"
              "--ozone-platform=wayland"
            ];
            jres = [
              pkgs.jre8
              pkgs.temurin-jre-bin-17
            ];
          };
        }
      ];
    };
  };
}
```

---

## ⚙️ Опции Home Manager модуля

| Опция                           | Тип               | По умолчанию | Описание                                  |
| ------------------------------- | ----------------- | ------------ | ----------------------------------------- |
| `programs.xmcl.enable`          | `bool`            | `false`      | Включает установку XMCL                   |
| `programs.xmcl.commandLineArgs` | `list of string`  | `[]`         | Дополнительные аргументы командной строки |
| `programs.xmcl.jres`            | `list of package` | `[]`         | Список JRE, доступных XMCL                |

---

