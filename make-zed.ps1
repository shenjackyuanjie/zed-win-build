$current_pos = Get-Location
Write-Host "当前位置：$current_pos"

# 依赖: https://github.com/jborean93/PSToml
Import-Module PSToml

Write-Host "Zed build script"
Write-Host "by shenjackyuanjie"
$_version_ = "1.2.1"
Write-Host "Version: $_version_"

$zed_repo_path = "V:\githubs\zed"
$work_path = "D:\path-scripts"

Set-Location $zed_repo_path
Write-Host "更新 Zed 仓库"
git pull | Tee-Object -Variable git_result
# 如果命令行参数包含 -f 则继续构建
if ($git_result -eq "Already up to date." -and -not ($args -contains "-f")) {
    Write-Host "Zed 仓库已经是最新的了"
    Set-Location $current_pos
    return
}
Write-Host "更新 Zed 仓库完成"

# 准备构建信息
$date = Get-Date -Format "yyyy-MM-dd-HH_mm_ss"
Write-Host "更新时间: $date"
$commit = git log -1 --pretty=format:"%h"
$full_commit = git log -1 --pretty=format:"%H"
$cargo_info = Get-Content ".\crates\zed\Cargo.toml" | ConvertFrom-Toml
$zed_version = $cargo_info.package.version
Write-Host "Zed 版本: $zed_version"
Write-Host "最新提交: $commit($full_commit)"
Write-Host "  - rustc flag: $env:RUSTFLAGS"
$zip_name = "zed-$zed_version-$commit.zip"
$zip_namex = "zed-$zed_version-$commit.zipx"
Write-Host "ZIP 名称：$zip_name"
Write-Host "ZIPX 名称：$zip_namex"
# 上面这堆信息构建完会再输出一遍

# build!
$start_time = Get-Date
if (-not ($args -contains "-skip")) {
    Write-Host "开始构建"
    cargo build --release
    Write-Host "构建完成, 耗时：$((Get-Date) - $start_time)"
}

# 把最新构建 copy 到 D:\path-scripts
Copy-Item -Path ".\target\release\Zed.exe" -Destination "$work_path\Zed.exe" -Force

# 到 D:\path-scripts 目录
Set-Location $work_path
if (Test-Path $zip_name) {
    Write-Host "删除旧 ZIP"
    Remove-Item -Path $zip_name -Force
}
Write-Host "开始打包"

# 创建一个 zed-zip 文件夹
if (-not (Test-Path ".\zed-zip")) {
    New-Item -ItemType Directory -Name "zed-zip" -Force
}

# 忽略输出
bz.exe c -l:9 -y -fmt:zip -t:14 -cp:65001 .\zed-zip\$zip_name .\Zed.exe
bz.exe c -l:9 -y -fmt:zipx -t:14 -cp:65001 .\zed-zip\$zip_namex .\Zed.exe
bz.exe t .\zed-zip\$zip_name
bz.exe t .\zed-zip\$zip_namex

$zip_file = Get-Item ".\zed-zip\$zip_name"
$zipx_file = Get-Item ".\zed-zip\$zip_namex"

Write-Host "tag: $zed_version+$commit-$_version_"
# https://github.com/zed-industries/zed/commit/f6fa6600bc0293707457f27f5849c3ce73bd985f
Write-Host "commit url: https://github.com/zed-industries/zed/commit/$full_commit"
Write-Host "打包信息:"
Write-Host "  - 脚本版本号: $_version_"
Write-Host "  - rustc flag: $env:RUSTFLAGS"
Write-Host "  - commit id: $commit"
Write-Host "  - Zed 版本号: $zed_version"
Write-Host "  - ZIP 文件: $zip_file"
Write-Host "  - ZIPX 文件: $zipx_file"
Write-Host "  - 构建时间：$date"
Write-Host "  - 构建耗时：$((Get-Date) - $start_time)"

Write-Host "``````"
# 计算 hash
Write-Host "blake3sum:"
b3sum.exe .\zed-zip\$zip_name
b3sum.exe .\zed-zip\$zip_namex

($zip_file, $zipx_file) | Get-FileHash -Algorithm SHA256
Write-Host "``````"
Write-Host "ZIP 压缩完成"

# 返回原位置
Set-Location $current_pos
