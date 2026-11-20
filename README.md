# 华硕天选 A15（FA507UU）黑苹果 EFI 使用说明

> 机型：ASUS TUF GAMING A15 FA507UU ｜ 平台：AMD Ryzen 7 8845H + NVIDIA RTX 4050 Laptop
> 系统：macOS 26.0 Tahoe（25A354 / Darwin 25.0.0）｜ 引导：OpenCore（UEFI）
> 更新日期：2026-11-20 ｜ 适用 EFI：`/EFI/OC`（本文全部参数取自该份 config.plist 实测）

***

## 一、概览

| 项目     | 内容                                                      |
| ------ | ------------------------------------------------------- |
| 主板平台   | AMD Ryzen 7 8845H（8 核 16 线程，Zen 4）                      |
| 独显     | NVIDIA GeForce RTX 4050 Laptop 6GB（Metal 3，NullMoth 驱动） |
| 核显     | AMD Radeon 780M（`0x1900`，EFI 内主动禁用，无驱动方案）               |
| 内屏     | BOE NE156FHM-NX6，1920×1080 @144Hz                       |
| 内存     | 16 GB                                                   |
| 网卡     | Realtek RTL8852BE / AW-XB547NF（M.2 2230，第三方 RTW89 驱动）   |
| 有线网卡   | Realtek RTL8111                                         |
| 声卡     | Realtek ALC256（`10EC:0256`，subsystem `1043:1C23`）       |
| 蓝牙     | Realtek（USB 通道，RealtekBluetoothFirmware 驱动）             |
| SMBIOS | MacBookPro16,2（`UpdateSMBIOSMode=Custom`）               |
| 引导分区   | 独立 FAT32（314.6 MB）ESP，卷名存在编码异常（显示为 `MACÊ²Á╝`），属正常现象     |
| 系统盘    | APFS 容器 100 GB，卷名 `Tahoe`                               |

**仓库内容**

| 文件 | 说明 |
|---|---|
| `README.md` | 本文档（硬件、驱动、config 参数、安装流程、限制与排障） |
| `LICENSE` | MIT 授权 + 第三方 kext 版权说明（kext 版权归各原作者） |
| `.gitignore` | 忽略 `*.bak`、`opencore-*.txt`、镜像文件等不入库内容 |
| `EFI/OC/` | OpenCore 引导目录（ACPI / Drivers / Kexts / config.plist） |

**总体定位**：日常可用级黑苹果。USB、蓝牙（经典 HID）、音频（输入输出）、Wi-Fi（可联网）、有线网、电池、摄像头、144Hz 内屏均已打通；AMD CPU 电源管理 kext 已加载（频率与温度需用 AMD Power Gadget 等工具查看）；**AirDrop / 接力 / 亮度调节 / 核显 / 硬件视频解码受硬件与驱动限制不可用**（详见第八节）。

***

## 二、镜像来源（安装介质）

| 字段   | 内容                      |
| ---- | ----------------------- |
| 镜像名称 | macOS 26 Tahoe 恢复版镜像    |
| 版本号  | 26.0                    |
| 镜像大小 | 16.19 GB                |
| 镜像类型 | 恢复版                     |
| 镜像文件 | `.rdr`（R-DriveImage 格式） |
| 初始密码 | `1111`                  |
| 资源来源 | 老吴黑苹果                   |

下载地址：

* 百度云：`https://pan.baidu.com/s/1rQ-mKeWzKJDxPbop1qaH8w?pwd=1234`

* 123 盘：`https://www.123865.com/s/zUV8Vv-LAzLH`

* 阿里云盘：`https://www.alipan.com/s/DZCMHsBaz5F`（下载后把 `.pdf` 后缀改为 `.rdr`）

* 夸克盘：`https://pan.quark.cn/s/95c82f25847b`

> 恢复版镜像的用法：用 **R-DriveImage** 把 `.rdr` 还原到一个 ≥ 镜像大小的分区（Windows 下可直接操作）。还原后该分区即为可启动的 macOS 系统盘，EFI 需放入该盘的 EFI 分区。

***

## 三、EFI 目录结构

```
EFI/
└── OC/
    ├── ACPI/                 # 8 个 SSDT（含 .dsl 源码，便于二次修改）
    ├── Drivers/              # apfs_aligned.efi / HfsPlus.efi / OpenRuntime.efi / ResetNvramEntry.efi
    ├── Kexts/                # 28 个 kext（详见第四节，其中 UTBDefault 为备用未启用）
    ├── Resources/            # Font / Image / Label（引导界面素材）
    ├── OpenCore.efi          # 872,448 字节
    ├── config.plist          # 主配置文件（本文所有参数来源）
    ├── config.plist.before-ALIBFix-20261031-120121.bak   # 本地备份，不入库
    └── config.plist.manual-backup-20261031-130036.bak   # 本地备份，不入库
```

***

## 四、驱动清单（Kexts）

加载顺序即 `Kernel/Add` 中的顺序，**顺序不可随意调换**（依赖关系已用箭头标注）。

| #  | Kext                        | 版本          | 作用                               | 状态     |
| -- | --------------------------- | ----------- | -------------------------------- | ------ |
| 1  | Lilu                        | 1.7.3       | 内核补丁框架，所有 Acidanthera 插件的基础      | 启用     |
| 2  | IOSkywalkFamily             | 1.0         | 网络栈依赖（配合 Block 替换系统版本）           | 启用     |
| 3  | IO80211FamilyLegacy         | 1200.12.2b1 | 旧版 802.11 家族栈（第三方网卡必需）           | 启用     |
| 4  | AMFIPass                    | 1.4.1       | 在 AMFI 关闭环境下放行签名校验               | 启用     |
| 5  | AirPort\_RTW89              | 0.6.0       | Realtek 8852 系列 Wi-Fi 驱动         | 启用     |
| 6  | ↳ AirPortRTW89Front（PlugIn） | —           | RTW89 前端插件，必须跟在其后                | 启用     |
| 7  | SimpleHDA                   | 1.0.0       | AppleHDA 替代栈（Tahoe 环境下 HDA 音频核心） | 启用     |
| 8  | AppleALC                    | 1.9.9（定制）   | ALC256 布局注入（Layout-ID 97）        | 启用     |
| 9  | XHCILagFix                  | 0.1.0       | 修复 AMD XHCI 控制器 USB 卡顿           | 启用     |
| 10 | RealtekBluetoothFirmware    | 1.0.2       | Realtek 蓝牙固件上传                   | 启用     |
| 11 | BlueToolFixup               | 2.7.3       | 蓝牙协议栈补丁                          | 启用     |
| 12 | BTSmpFixup                  | 2.7.3       | 蓝牙 SMP（BLE 配对）补丁                 | 启用     |
| 13 | AppleMCEReporterDisabler    | 1.2         | 关闭 MCE 上报，避免 AMD 平台内核崩溃          | 启用     |
| 14 | BrightnessKeys              | 1.0.4       | 亮度快捷键映射（本机背光不可用，保留无副作用）          | 启用     |
| 15 | NVMeFix                     | 1.1.4       | NVMe 电源管理 / 兼容性修补                | 启用     |
| 16 | RealtekRTL8111              | 2.4.2       | 有线网卡驱动                           | 启用     |
| 17 | RestrictEvents              | 1.1.7       | 屏蔽不必要的系统更新 / 机型相关报错              | 启用     |
| 18 | VirtualSMC                  | 1.3.9       | SMC 模拟核心（电池 / 温度 / 风扇等传感器基础）     | 启用     |
| 19 | AMDRyzenCPUPowerManagement  | 3.34.0      | AMD Ryzen 频率与电源状态管理              | 启用     |
| 20 | SMCAMDProcessor             | 3.34.0      | 把 CPU 频率 / 温度发布为 SMC 传感器（依赖 #19） | 启用     |
| 21 | SMCBatteryManager           | 1.3.9       | 电池电量 / 循环次数                      | 启用     |
| 22 | SMCLightSensor              | 1.3.9       | 环境光传感器                           | 启用     |
| 23 | USBToolBox                  | 1.2.0       | USB 端口映射框架                       | 启用     |
| 24 | UTBMap                      | 1.1         | 本机 USB 端口映射数据（**与机型强绑定**）        | 启用     |
| 25 | ↳ VoodooI2CServices         | —           | I2C 服务插件                         | 启用     |
| 26 | ↳ VoodooGPIO                | —           | GPIO 控制器                         | 启用     |
| 27 | VoodooI2C                   | 2.9.1       | I2C 触控板 / 触摸屏                    | 启用     |
| 28 | ↳ VoodooInput（I2C 侧）        | 1.1.7       | 触控板输入抽象                          | 启用     |
| 29 | VoodooI2CHID                | 1.0         | I2C HID 设备                       | 启用     |
| 30 | VoodooPS2Controller         | 2.3.8       | PS/2 键盘（内建键盘）                    | 启用     |
| 31 | ↳ VoodooInput（PS2 侧）        | —           | 与 I2C 侧重复，避免冲突而关闭                | **禁用** |
| 32 | ↳ VoodooPS2Keyboard         | —           | 内建键盘                             | 启用     |
| 33 | ↳ VoodooPS2Mouse            | —           | PS/2 鼠标设备                        | 启用     |
| 34 | ↳ VoodooPS2Trackpad         | —           | PS/2 触控板                         | 启用     |
| 35 | WhateverGreen               | 1.7.2       | 显卡补丁（本机 NVIDIA 方案由 NullMoth 承担）  | **禁用** |

附带未使用的备用件：`UTBDefault.kext`（USBToolBox 默认映射，本机未启用，改用 `UTBMap.kext`）。

***

## 五、ACPI（SSDT）清单

| 文件                              | 状态 | 说明                                                      |
| ------------------------------- | -- | ------------------------------------------------------- |
| `SSDT-EC.aml`                   | 启用 | 生成 EC 设备，满足电源 / 电池相关依赖                                  |
| `SSDT-PLUG-ALT.aml`             | 启用 | CPU 电源管理注入（AMD 用 ALT 版本）                                |
| `SSDT-USBX.aml`                 | 启用 | USB 供电属性（充电电流上限）                                        |
| `SSDT-XOSI.aml`                 | 启用 | 操作系统判断伪装（配合 `_OSI` 重命名）                                 |
| `SSDT-ALIBFix.aml`              | 启用 | ALC 声卡相关修补（本机定制）                                        |
| `SSDT-PNLF.aml`                 | 启用 | 背光控制设备（**本机无效**：引用 `\_SB.PCI0.GFX0`，AMD 平台无该节点，保留不影响启动） |
| `SSDT-Disable_Network_GPP6.aml` | 禁用 | 关闭某 PCI 网络设备（备用方案）                                      |
| `SSDT-USB-Reset.aml`            | 禁用 | USB 复位工具（排障用，平时关闭）                                      |

每个 `.aml` 均附带同名 `.dsl` 源文件，便于按需重编译。

***

## 六、config.plist 关键配置

### 6.1 boot-args（NVRAM，GUID `7C436110-AB2A-4BBB-A880-FE41995C9F82`）

```
-vi2c-force-polling revpatch=sbvmm nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth
amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4
-btlfxboardid -btlfxallowanyaddr -btsmpforce
alcid=97 alcverbs=1 alctcsel=1 -amfipassbeta keepsyms=1
```

| 参数                                                     | 作用                                                      |
| ------------------------------------------------------ | ------------------------------------------------------- |
| `-vi2c-force-polling`                                  | VoodooI2C 强制轮询模式，规避本机 GPIO 中断问题                         |
| `revpatch=sbvmm`                                       | RestrictEvents 修补 Board-ID，让系统更新通道可用                    |
| `nvfb=1` / `nvaccel=1`                                 | NullMoth NVIDIA 驱动：启用帧缓冲 / 硬件加速                         |
| `nvfbheads=4`                                          | 帧缓冲头数量（多屏支持）                                            |
| `-nvkmsnosmooth`                                       | 关闭 NVIDIA 驱动的平滑帧同步（本机稳定性需要）                             |
| `gfxrst=4`                                             | GPU 复位策略（4 = 更激进的复位，避免挂起）                               |
| `amfi_get_out_of_my_way=0x1` / `amfi=0x80`             | 关闭 AMFI，允许未签名 kext 与补丁                                  |
| `ipc_control_port_options=0`                           | 关闭 IPC 控制端口限制（OCLP 类补丁环境需要）                             |
| `-btlfxboardid` / `-btlfxallowanyaddr` / `-btsmpforce` | 蓝牙补丁：放宽 Board-ID 校验、允许任意地址、强制 SMP                       |
| `alcid=97`                                             | AppleALC 布局 ID 97（本机 ALC256 定制布局）                       |
| `alcverbs=1` / `alctcsel=1`                            | 启用 AppleALC verbs 与 codec 选择                            |
| `-amfipassbeta`                                        | AMFIPass 在 Tahoe 上以 beta 模式生效                           |
| `keepsyms=1`                                           | **SimpleHDA 必需**（缺此项声音会完全失效）；不影响 `DisplayLevel=0` 的静默启动 |

其它 NVRAM 项：`csr-active-config = 0x0A43`（SIP 部分关闭，第三方 kext / 补丁环境需要）；`NVRAM/Delete` 中显式删除 `boot-args`，这是本机 boot-args 能生效的关键（否则改参数无效）。

### 6.2 Kernel/Block

| Identifier                        | Strategy | Arch    | MinKernel |
| --------------------------------- | -------- | ------- | --------- |
| `com.apple.iokit.IOSkywalkFamily` | Exclude  | x86\_64 | 23.0.0    |

作用：屏蔽系统自带 IOSkywalkFamily，改用注入版本，是第三方 Wi-Fi 栈能工作的前提，**不可删除**。

### 6.3 Misc / Boot

| 项                | 值        |
| ---------------- | -------- |
| PickerMode       | Builtin  |
| PickerAttributes | 17       |
| Timeout          | 5 秒      |
| ShowPicker       | true     |
| HideAuxiliary    | false    |
| HibernateMode    | None     |
| LauncherOption   | Disabled |

### 6.4 Misc / Security

| 项                    | 值        | 说明               |
| -------------------- | -------- | ---------------- |
| SecureBootModel      | Disabled | 关闭安全启动模型（第三方栈必需） |
| Vault                | Optional | 未启用保险库           |
| ScanPolicy           | 0        | 扫描所有设备（多系统启动方便）  |
| DmgLoading           | Signed   | 仅加载签名 DMG        |
| BlacklistAppleUpdate | true     | 拦截 Apple 固件更新    |
| ExposeSensitiveData  | 7        | 暴露序列号等信息给系统      |

### 6.5 Misc / Debug

| 项                       | 值      | 说明                             |
| ----------------------- | ------ | ------------------------------ |
| DisplayLevel            | **0**  | 屏幕不打印 OpenCore 日志（已关闭滚动日志）     |
| Target                  | **67** | 仍写入 `opencore-*.txt` 文件日志，便于排障 |
| AppleDebug / ApplePanic | true   | 保留内核日志与 panic 记录               |
| DisableWatchDog         | true   | 关闭看门狗                          |

> 想临时看屏幕日志：把 `DisplayLevel` 改回 `0x80000002`；`keepsyms=1` 不要删（删了没声音）。

### 6.6 PlatformInfo（机型信息）

| 字段                 | 值                                      |
| ------------------ | -------------------------------------- |
| SystemProductName  | MacBookPro16,2                         |
| ProcessorType      | 3841（显示为 "8-Core Intel Xeon W"）        |
| UpdateSMBIOSMode   | Custom                                 |
| Automatic          | true                                   |

> **说明**：本文档不含任何 SMBIOS 三码（序列号 / MLB / ROM / UUID）。
> 使用者请用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 或 OpenCore Configurator 自行生成一套独占的三码，
> 不要复制他人的三码，也不要与他人共用（会导致 iMessage / App Store 互相踢下线）。

### 6.7 DeviceProperties

| 设备路径                                     | 属性                 | 作用                             |
| ---------------------------------------- | ------------------ | ------------------------------ |
| `PciRoot(0x0)/Pci(0x1,0x1)/Pci(0x0,0x0)` | `acpi-wake-type=1` | 无线网卡唤醒类型                       |
| `PciRoot(0x0)/Pci(0x2,0x1)/Pci(0x0,0x0)` | `built-in=01`      | 有线网卡标记为内建（iCloud/App Store 需要） |
| `PciRoot(0x0)/Pci(0x8,0x1)/Pci(0x0,0x0)` | `disable-gpu=true` | 禁用 Radeon 780M 核显              |

### 6.8 Quirks（已启用项）

* **Booter**：`AvoidRuntimeDefrag`、`DevirtualiseMmio`、`DisableVariableWrite`、`EnableSafeModeSlide`、`FixupAppleEfiImages`、`ProvideCustomSlide`、`RebuildAppleMemoryMap`、`SetupVirtualMap`、`SyncRuntimePermissions`、`AllowRelocationBlock`

* **Kernel**：`CustomSMBIOSGuid`、`DisableLinkeditJettison`、`DisableRtcChecksum`、`PanicNoKextDump`、`PowerTimeoutKernelPanic`、`ProvideCurrentCpuInfo`

* **UEFI**：`EnableVectorAcceleration`、`ReleaseUsbOwnership`、`RequestBootVarRouting`

***

## 七、安装流程

### 7.1 用 1401 工具制作启动 U 盘

1. 在 Windows 下运行 **1401 工具**（黑苹果工具，界面与选项随版本略有差异，以其自带说明为准）
2. 选择 macOS 恢复镜像（本仓库为 `.rdr` 恢复版），目标选 U 盘（**≥ 16 GB，会被完全清空**）
3. 按提示写入，工具会自动处理分区与引导
4. 写入完成后 U 盘应具备两块内容：引导用 EFI 分区 + 系统恢复分区

### 7.2 启动并恢复系统到硬盘

1. 用该 U 盘启动，进入 1401 的恢复/安装流程
2. 若 1401 支持直接把恢复镜像写入硬盘分区，按其提示操作；也可退出后用 **R-DriveImage** 将 `.rdr`（密码 `1111`）还原到一个 ≥ 镜像大小的分区
3. 恢复完成后，该分区即为可启动的 macOS 系统盘（本机为 100 GB APFS 容器，卷名 `Tahoe`）

### 7.3 放置 EFI 与 BIOS 设置

1. **放置 EFI**：挂载该系统盘的 EFI 分区（ESP），把本仓库 `EFI/OC` 整个放入。若 ESP 内已有 Windows 引导，**保留 `EFI/Microsoft` 目录**，只替换 `EFI/OC` 与 `EFI/BOOT/BOOTx64.efi`
2. **BIOS 设置**：关闭 Secure Boot、关闭 CSM、开启 Above 4G Decoding、开启 XHCI Hand-off

### 7.4 进入 macOS 后写入 NVIDIA 显卡驱动（1401 工具）

本机显卡为 **NVIDIA RTX 4050 Laptop**，macOS 无官方驱动，需在系统能启动之后用 1401 的显卡驱动功能写入第三方驱动（NullMoth）：

1. 首次进入 macOS 桌面后，再次运行 1401，选择显卡驱动（NVIDIA 驱动）相关功能
2. 按提示把驱动写入系统；此步骤会改动系统卷，属正常现象，具体选项见 1401 说明
3. 写入完成并重启；本 EFI 已内置配套 boot-args：`nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth gfxrst=4`
4. 验证：`系统信息 → 图形 / 显示器` 应显示 **Metal 3**、内屏 1920×1080 @144Hz；若显示 "No Kext Loaded" 或黑屏，说明驱动未写入成功

> 注意：显卡驱动需与系统大版本匹配。升级 macOS 后要重新用 1401 写入对应版本的 NVIDIA 驱动，否则可能黑屏或退化为无加速模式。

### 7.5 首次启动与验收

1. 选择 OpenCore 引导 → 进引导菜单后**先执行一次 Reset NVRAM**（本机 boot-args 依赖 `NVRAM/Delete`，不重置可能不生效）
2. 进入系统后按顺序验证：
   - 菜单栏出现音量图标、能拖音量 → 音频栈正常（`keepsyms=1` 生效）
   - 系统设置 → 声音 → 输入，说话看电平 → 麦克风
   - 关掉 Wi-Fi 再打开，能搜到网络并连上 → RTW89 正常
   - 插 U 盘、接鼠标 / 键盘、开蓝牙连经典设备 → USB 与蓝牙
   - `kmutil showloaded | grep -i -E "AMDRyzen|SMCAMD"` → 两条都应在
   - 关于本机 → 1920×1080 @144Hz

***

## 八、已实现功能 与 已知限制

### 8.1 已验证可用

| 功能                        | 状态 |
| ------------------------- | -- |
| 启动 / 图形界面（NVIDIA Metal 3） | ✅  |
| 内屏 1920×1080 @144Hz       | ✅  |
| USB（含 U 盘、iPhone 热点共享）    | ✅  |
| 蓝牙经典设备（键盘 / 鼠标）           | ✅  |
| 音频输出 + 麦克风输入              | ✅  |
| Wi-Fi 联网（Realtek RTW89）   | ✅  |
| 有线网（RTL8111）              | ✅  |
| 电池电量 / 循环次数 / 充电状态        | ✅  |
| 摄像头（UVC 已识别）              | ✅  |
| iCloud 登录                   | ✅  |
| AMD CPU 电源管理 kext 已加载      | ✅  |
| 内建键盘 / 触控板                | ✅  |

> 触控板已实测可用（指针移动 + 点击正常），驱动来自 `VoodooI2C 2.9.1`（配合 `VoodooI2CHID`）与 `VoodooPS2Controller 2.3.8` 双栈；三指 / 四指等高级手势未逐项实测，如需完整手势可继续调 `VoodooI2CHID` 的 GPIO 中断配置。

### 8.2 已知限制（多为硬件天花板）

| 限制                                      | 原因                                                                                                     | 可行出路                              |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------- |
| **AirDrop / 接力 / 随航 / 通用控制 / iPhone 镜像** | Realtek 网卡无 AWDL 能力（驱动 README 明确 "Not yet: AirDrop/AWDL/Continuity"）                                   | 换博通 `BCM94360NG`（M.2 2230），详见附录 A |
| **蓝牙耳机（A2DP）、BLE 鼠标**                   | Realtek 控制器能力限制：经典音频 `AUTHENTICATION_FAILURE`/`705`，BLE HID `addScanFilterByUUID 0x1812` 失败            | 换博通卡后随之解决                         |
| **屏幕亮度调节**                              | 面板不回应背光查询（`backlight: no internal display answered the brightness query`），`AppleBacklightDisplay` 从未注册 | 软件遮罩调光（见附录 B），真背光无解               |
| **Radeon 780M 核显**                      | macOS 无驱动（`No Kext Loaded`），EFI 内已主动 `disable-gpu`                                                     | 无                                 |
| **NVIDIA 硬件视频解码**                       | macOS 无 VideoToolbox 硬件解码路径                                                                            | 播放器侧软解 / 优化                       |
| **SSDT-PNLF 无效**                        | 引用 Intel 路径 `\_SB.PCI0.GFX0`，AMD 平台不存在该节点                                                              | 可删（不影响启动）                         |

***

## 九、维护与回滚

* **改配置前必做**：`cp config.plist ../OC-Backups-YYYYMMDD-HHMMSS/config.plist.before-<改动>`，命名含改动内容与时间戳

* **常用回滚点**：`config.plist.before-wifi`（Wi-Fi 前）、`before-alc`（声卡前）、`before-quietboot`（静默启动前）、`before-amdpm`（AMD 电源管理前）、`before-keepsyms`（声音修复前）

* **校验**：任何手工编辑后执行 `plutil -lint config.plist`

* **改 EFI 后**：`sync` 再重启，避免缓存未落盘

* **升级 macOS 前**：备份整份 EFI；确认 `revpatch=sbvmm` 与 `SecureBootModel=Disabled` 保持；大版本升级后需重新确认 kext 兼容性（尤其 RTW89、SimpleHDA、NullMoth 三套第三方栈）

***

## 十、常见问题（FAQ）

**Q1：声音全没了，系统里没有输出设备？**

`keepsyms=1` 被删了。SimpleHDA 里写明 `requires-keepsyms-1`，缺少该参数会导致 HDA 控制器挂不上（`AppleHDAController` 对象数为 0）。补回参数重启即可。

**Q2：改了 boot-args 却没生效？**

检查 `NVRAM/Delete` 的 `7C436110-...` 分支里是否仍有 `boot-args`，并在引导菜单执行一次 Reset NVRAM。

**Q3：开机又出现一堆滚动日志？**

看 `Misc/Debug/DisplayLevel` 是否为 `0`。注意 `keepsyms=1` 与屏幕日志无关，别一起删。

**Q4：Wi-Fi 能搜到但连不上 / 完全没有 Wi-Fi 条目？**

依次确认：`IOSkywalkFamily.kext` 已注入 → `Kernel/Block` 中 `com.apple.iokit.IOSkywalkFamily` 存在 → `IO80211FamilyLegacy` 在 `IOSkywalkFamily` 之后 → `AirPort_RTW89` 与 `AirPortRTW89Front` 顺序正确 → boot-args 含 `-amfipassbeta`。

**Q5：USB 全部失效 / 插拔卡顿？**

`UTBMap.kext` 与本机端口映射强绑定，换主板或改 BIOS 后需用 USBToolBox 重新映射；卡顿则确认 `XHCILagFix.kext` 已启用。

**Q6：可以睡眠吗？**

未验证。该驱动组合（NullMoth + 第三方 Wi-Fi/BT）对睡眠 / 唤醒支持不佳，建议 `sudo pmset -a sleep 0`，或需要时再单独排查。

**Q7：iMessage / FaceTime 能用吗？**

SMBIOS 已配置完整（MLB/ROM/UUID 齐全，iCloud 可登录），但需实测。若提示需要验证，检查三码是否与 ROM 匹配，且不要与他人共用同一套三码。

***

## 十一、免责声明

1. 本 EFI 仅面向同型号（或高度相似）硬件，直接套用其它机型可能无法启动甚至损坏系统分区数据。

2. 黑苹果涉及修改固件级引导，操作前请**务必备份重要数据**；作者不对任何数据丢失、硬件损坏、账号风控承担责任。

3. 本文档已移除全部 SMBIOS 三码（序列号 / MLB / ROM / UUID），使用者需自行生成，请勿与他人共用同一套。

4. 各 kext 版权归原作者，使用须遵守其各自许可证；Apple 相关组件（IOSkywalkFamily、IO80211FamilyLegacy 等）为 OCLP 分发，请遵守其许可条款。

***

## 附录 A：换博通网卡以启用 AirDrop（可选升级）

| 型号                     | 接口       | 价格参考             | 说明                                                                                      |
| ---------------------- | -------- | ---------------- | --------------------------------------------------------------------------------------- |
| **BCM94360NG**         | M.2 2230 | 100–200 元        | 首选：直接替换 RTL8852BE，免驱，支持 AirDrop / 接力 / 随航 / 通用控制 / iPhone 镜像；蓝牙走 USB（本机 M.2 插槽的 USB 通道已验证可用，BCM 卡本身未实测） |
| BCM94360CS2 + NGFF 转接卡 | M.2 + 转接 | 卡 60–150 元 + 转接卡 35 元 | 功能相同，需额外 USB 走线与天线，笔记本内部走线麻烦                                                            |
| BCM943224PCIEBT2       | M.2 / 转接 | 便宜               | 仅 802.11n，对现代设备几乎无用                                                                     |

换卡后 EFI 需同步调整：

1. 移除 `AirPort_RTW89.kext` 与 `AirPortRTW89Front` 两条 `Kernel/Add`

2. 保留 `Kernel/Block` 中的 `IOSkywalkFamily` 条目

3. 把 `IO80211FamilyLegacy.kext/Contents/PlugIns/AirPortBrcmNIC.kext` 加入 `Kernel/Add`（当前该插件已存在于包内但未注入）

4. 保留 `AMFIPass` 与 `-amfipassbeta`

5. 蓝牙侧可移除 `RealtekBluetoothFirmware`，`BlueToolFixup`/`BTSmpFixup`/`-btsmpforce` 亦可清理（原生博通蓝牙不需要）

***

## 附录 B：屏幕调光（软件方案）

真背光不可用，可用 "全屏黑色半透明遮罩" 压暗画面：不闪、不影响点击，代价是不省电、黑位抬高（暗部偏灰）。

* 相关工具：BetterDisplay（gamma 方案，**本机实测会持续闪烁，不可用**）、Iris（付费）、自制遮罩小工具

* 本机已验证有效的做法为遮罩类工具，默认压暗 18%，档位可选 10%–70%

***

## 附录 C：EFI 来源与致谢

| 来源                                                                               | 用途                                                                  |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `FDBEHE/FA507UV-Hackintosh`                                                      | 同款机型参考配置、ALC256 定制 AppleALC + SimpleHDA、AMD 电源管理 kext、USB/UTBMap 思路 |
| Acidanthera 项目（Lilu、VirtualSMC、AppleALC、NVMeFix、RestrictEvents、BrightnessKeys 等） | 基础驱动                                                                |
| `FranciumOS-org/AirPort_RTW89` v0.6.0-BETA                                       | Realtek Wi-Fi 驱动                                                    |
| OpenCore Legacy Patcher（IOSkywalkFamily / IO80211FamilyLegacy / AMFIPass）        | 网络栈与 AMFI 绕行                                                        |
| trulyspinach（AMDRyzenCPUPowerManagement / SMCAMDProcessor）                       | AMD CPU 电源管理                                                        |
| **1401 工具** | 制作启动 U 盘、写入 NVIDIA 显卡驱动（使用说明见工具自带文档） |
| Dortania OpenCore Install Guide                                                  | 通用配置依据                                                              |
