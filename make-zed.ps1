$current_pos = Get-Location
Write-Host "当前位置：$current_pos"
function main {
    
    Set-Location V:\githubs\zed
    Write-Host "更新 Zed 仓库"
    $git_result = git pull
    Write-Host "更新结果：$git_result"
    if ($git_result -eq "Already up to date.") {
        Write-Host "Zed 仓库已经是最新的了"
        return
    }
    Write-Host "更新 Zed 仓库完成"

    # 准备构建信息
    $date = Get-Date -Format "yyyy-MM-dd-HH_mm_ss"
    Write-Host "更新时间：$date"
    $commit = git log -1 --pretty=format:"%h"
    Write-Host "最新提交：$commit"
    $zip_name = "zed-$date-$commit-ziped.zip"
    $zip_namex = "zed-$date-$commit-ziped.zipx"
    Write-Host "ZIP 名称：$zip_name"
    Write-Host "ZIPX 名称：$zip_namex"
    # 上面这堆信息构建完会再输出一遍

    # build!
    Write-Host "开始构建"
    $start_time = Get-Date
    cargo build --release
    Write-Host "构建完成, 耗时：$((Get-Date) - $start_time)"

    # 把最新构建 copy 到 D:\path-scripts
    Copy-Item -Path ".\target\release\Zed.exe" -Destination "D:\path-scripts\Zed.exe" -Force

    # 到 D:\path-scripts 目录
    Set-Location "D:\path-scripts"
    if (Test-Path $zip_name) {
        Write-Host "删除旧 ZIP"
        Remove-Item -Path $zip_name -Force
    }
    Write-Host "开始打包"

    Write-Host "打包信息:"
    Write-Host "  - ZIP 名称：$zip_name"
    Write-Host "  - ZIPX 名称：$zip_namex"
    Write-Host "  - commit id: $commit"
    Write-Host "  - 构建时间：$date"
    Write-Host "  - 构建耗时：$((Get-Date) - $start_time)"

    # 创建一个 zed-zip 文件夹
    if (-not (Test-Path ".\zed-zip")) {
        New-Item -ItemType Directory -Name "zed-zip" -Force
    }

    # 忽略输出
    bz.exe c -l:9 -y -fmt:zip -t:14 -cp:65001 .\zed-zip\$zip_name .\Zed.exe > $null
    bz.exe c -l:9 -y -fmt:zipx -t:14 -cp:65001 .\zed-zip\$zip_namex .\Zed.exe > $null
    bz.exe t .\zed-zip\$zip_name > $null
    bz.exe t .\zed-zip\$zip_namex > $null

    # 计算 hash
    Write-Host "blake3sum:"
    b3sum.exe .\zed-zip\$zip_name
    b3sum.exe .\zed-zip\$zip_namex

    $zip_file = Get-Item ".\zed-zip\$zip_name"
    $zipx_file = Get-Item ".\zed-zip\$zip_namex"
    ($zip_file, $zipx_file) | Get-FileHash -Algorithm SHA256
    Write-Host "ZIP 压缩完成"
}

main

# 返回原位置
Set-Location $current_pos
