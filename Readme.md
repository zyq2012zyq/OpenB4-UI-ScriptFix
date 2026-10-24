# OpenB4 UI & Script Fix

Minecraft **1.8.9 Forge** 客户端模组。本项目基于 [abusez/OpenB4](https://codeberg.org/abusez/OpenB4)，加入可调整的 ClickGUI 缩放，以及脚本编译器和脚本滑条读取修复。原始 Raven B4 由 Chef 制作；OpenB4 的恢复与整理工作见上游仓库致谢。本仓库经授权公开再发布。

## 下载与安装

从 [最新版本](https://github.com/zyq2012zyq/OpenB4-UI-ScriptFix/releases/latest) 下载 `RavenB4.jar`，放入 **Minecraft 1.8.9 Forge** 实例的 `mods` 文件夹。移走旧版 B4 JAR，避免同一模组加载两次。启动游戏后，通过客户端原有的 GUI 按键打开 B4。

## 使用

- **调整界面大小：** 在 `Gui → Scale` 拖动滑条，范围 **1×–4×**、步长 **0.1×**，默认 **2×**。打开 B4 菜单时也可以按住 **Ctrl** 滚动鼠标滚轮调整。
- **导入配置：** 在 `Profiles → Manager → Open folder` 打开目录，放入 `.json` 配置文件，然后点 `Load profiles`；到 `Profiles` 分类点击配置名称启用。实际目录是当前游戏实例下的 `keystrokes/profiles`。
- **导入脚本：** 在 `Scripts → Manager → Open folder` 打开目录，放入 `.java` 脚本，然后点 `Load scripts`；加载后到 `Scripts` 分类启用。实际目录是当前游戏实例下的 `keystrokes/scripts`。新版 JAR 自带 Java 8 脚本编译器后备，因此使用不含编译器的 Java 8 运行时启动也能编译脚本。

## 修复内容

1. ClickGUI 缩放与鼠标点击、拖动、滚动裁剪同步，分辨率变化时重新排列分类。
2. 系统 JDK 编译器不存在时，从 JAR 内加载 Java 8 编译器。
3. 脚本在设置尚未注册时读取数值滑条，不再因 `Integer` 转 `Double` 抛出 `ClassCastException`。

完整记录见 [CHANGELOG.md](CHANGELOG.md)。

## 构建

源码在 `OpenB4/`，Gradle Wrapper 版本为 8.8。需要 **JDK 17** 运行 Gradle、**JDK 8** 编译目标字节码，以及 Python 3。Windows 下运行：

```powershell
.\tools\build-release.ps1 -Jdk8Home 'C:\path\to\jdk8' -Jdk17Home 'C:\path\to\jdk17'
```

产物在 `dist/RavenB4.jar`。`OpenB4` 的普通 Gradle 构建生成源码对应的 JAR；上面的发布脚本还会把 `vendor/RavenB4-scriptfix-input.jar` 中的第三方脚本修复类保留下来、加入 Java 8 编译器，并对脚本滑条接口做精确字节码修补。该脚本修复输入 JAR 只有二进制版本，所以发布脚本如实保留其 class，而没有声称其源码已完整恢复。Java 8 编译器来自 Eclipse Temurin；相关许可证和说明会一并打入产物。

## 更新与自动发布

每次完成修改时，在 `CHANGELOG.md` 写明更新，再提交。此仓库配置了 Git `post-commit` 钩子，**提交后自动推送到 GitHub**；GitHub Actions 会对每次推送重建 JAR、创建 Release，并把最新更新说明作为 Release 介绍。新克隆需运行一次 `git config core.hooksPath .githooks` 启用本地钩子。也可以使用 `tools/publish-update.ps1` 更新日志并提交。

## 来源与权利

本仓库保留上游 Git 历史，并明确标注 [OpenB4 上游](https://codeberg.org/abusez/OpenB4)。原作者和第三方组件的权利归各自权利人；本仓库没有为上游代码另行指定开源许可证。

---

English summary: A Minecraft 1.8.9 Forge build of OpenB4 with adjustable ClickGUI scale, bundled Java 8 script compiler fallback, and a numeric slider API fix. See the sections above for installation and build steps.
