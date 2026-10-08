# zed-win-build

> [!IMPORTANT]
> **Discontinued / 已停止维护**
>
> Zed now provides **official Windows builds**. This repository's unofficial Windows builds and releases are no longer maintained. **Please use the official distribution instead: [Download Zed](https://zed.dev/download).**
>
> Zed 现已正式提供 **Windows 版本**。本仓库提供的非官方 Windows 构建及发行包已停止维护，不再更新。**请改用 [Zed 官方下载页面](https://zed.dev/download) 获取 Windows 版。**

## Get Zed for Windows / 获取 Windows 版 Zed

- **Official download / 官方下载：** https://zed.dev/download
- **Windows installation guide / Windows 安装文档：** https://zed.dev/docs/windows
- **Windows package manager / Windows 包管理器：** `winget install -e --id ZedIndustries.Zed`

## About this repository / 关于本仓库

This project previously distributed **unofficial Zed builds for Windows** before official Windows builds were available. It is retained for historical reference only. Old binaries and build scripts here are **not supported or updated**.

在 Zed 官方提供 Windows 版本之前，本项目曾用于分发 **Zed 的非官方 Windows 构建**。仓库后续仅作为历史资料保留，其中旧版本的安装包与构建脚本 **不再维护或更新**。

## Historical build script / 历史构建脚本

### `make-zed.ps1`

Legacy script previously used to prepare release artifacts; kept for reference and **not recommended for current Zed installations**.

此脚本原用于构建 Release 中的内容，仅供参考，**不建议再用于安装当前版本的 Zed**。

Historical dependency / 历史依赖：
- [PSToml](https://github.com/jborean93/PSToml)
- `Install-Module -Name PSToml -Scope CurrentUser`
