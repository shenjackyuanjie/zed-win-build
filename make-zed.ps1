$current_pos = Get-Location
Write-Host "当前位置：$current_pos"

# 依赖: https://github.com/jborean93/PSToml
Import-Module PSToml

Write-Host "Zed build script"
Write-Host "by shenjackyuanjie"
$_version_ = "1.3.4"
# 版本号
# 1.3.4 现在在结束 zed 进程之后会等 1s 让他完全结束
# 1.3.3 现在如果带有 -f, git pull 会直接拉取, 不再判断是否已经是最新的(这样终端就有颜色了)
# 1.3.2 修复分支信息导致的文件名错误
# 1.3.1 添加已有 zed 检测和结束
# 1.3.0 添加分支信息输出
# 1.2.1 添加 rustc flag 输出
Write-Host "Version: $_version_"

$zed_repo_path = "V:\githubs\zed"
$work_path = "D:\path-scripts"

Set-Location $zed_repo_path
Write-Host "更新 Zed 仓库"
if ($args -contains "-f") {
    # 直接拉取
    git pull
}
else {
    git pull | Tee-Object -Variable git_result
    if ($git_result -eq "Already up to date.") {
        Write-Host "Zed 仓库已经是最新的了"
        Set-Location $current_pos
        return
    }
}
Write-Host "更新 Zed 仓库完成"

# 准备构建信息
$date = Get-Date -Format "yyyy-MM-dd-HH_mm_ss"
Write-Host "更新时间: $date"
$commit = git log -1 --pretty=format:"%h"
$branch = git branch --show-current
$full_commit = git log -1 --pretty=format:"%H"
$cargo_info = Get-Content ".\crates\zed\Cargo.toml" | ConvertFrom-Toml
$zed_version = $cargo_info.package.version
Write-Host "Zed 版本: $zed_version"
Write-Host "最新提交: $commit($full_commit)"
Write-Host "分支: $branch"
Write-Host "rustc flag: $env:RUSTFLAGS"
# 如果 branch 名称中有 / 则替换为 _
$branch_path = $branch -replace "/", "_"
$zip_name = "zed-$zed_version-$branch_path-$commit.zip"
$zip_namex = "zed-$zed_version-$branch_path-$commit.zipx"
Write-Host "ZIP 名称：$zip_name"
Write-Host "ZIPX 名称：$zip_namex"
# 上面这堆信息构建完会再输出一遍

# build!
$start_time = Get-Date
if (-not ($args -contains "-skip")) {
    Write-Host "开始构建"
    cargo build --release --timings
    Write-Host "构建完成, 耗时：$((Get-Date) - $start_time)"
}

# 先看看有没有 zed.exe 正在运行
$zed_process = Get-Process -Name zed -ErrorAction SilentlyContinue
if ($zed_process) {
    Write-Host "Zed 进程存在，结束进程(并等待1s)"
    Stop-Process $zed_process -Force
    Start-Sleep -Seconds 1
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
Write-Host "  - 分支: $branch"
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
