$original_game_path = "E:\Games\steamapps\common\IL-2 Sturmovik Battle of Stalingrad"
$original_startup_file_path = "$original_game_path\data\startup.cfg"
$original_exe_file_path = "$original_game_path\bin\game\Il-2.exe"
$il2args=
$replacer_settings_path = "settings"
$selected_startup_file_path = ""

$setting_list = @()
# {
#     filename: filename,
#     settings: {
#         fullscreen: 0,
#         full_height
#     }
#     summery: "filename=......"
# }

function Get-HeaderMessage() {
    $message = "IL2 BoS 設定オーバーライドスクリプト"
    $message += "`nBackup original setting file and overwrite, then run il2"
    $message += "`noriginal file will restore after il2 exited"
    return $message
}

function Get-SummeryHashToString {
    param($local:filename, $fullscreen, $height, $width)
    return "fullscreen=$local:fullscreen , width=$width , height=$height `n"
}

# ファイルを解析して設定をハッシュで返す
function AnalyzeFile($local:path) {
    $local:content = Get-Content($local:path)
    $local:hash = @{}
    foreach($row in $local:content) {
        if ($row.Substring(0,1) -eq "[") {
            continue
        }
        $trimed = $row.Replace("`t", "").Replace(" ", "")
        $key_value = $trimed -split "="
        if ($key_value.Length -lt 2) {
            continue
        }
        $local:hash[$key_value[0]] = $key_value[1]
    }
    $msg = ""
    if ($local:hash.fullscreen -eq "0") {
        # windowed
        $msg = GET-SummeryHashToString $local:path.PSChildName $local:hash.fullscreen $local:hash.win_height $local:hash.win_width
    } else {
        # full screen
        $msg = GET-SummeryHashToString $local:path.PSChildName $local:hash.fullscreen $local:hash.full_height $local:hash.full_width
    }
    return @{
        filename=$local:path;
        settings=$local:hash;
        summary=$msg
    }
}

# ファイルから任意の設定を見つける
function Get-CfgValue() {
    param([int]$fileidx, [string]$setting_key)
    return $setting_list[$fileidx]["settings"][$setting_key]
}

# ----------------------------------------------------------------------

# Greetings
$greeting = Get-HeaderMessage
Write-Output $greeting

# フォルダのcfgファイルをすべて解析
$filenames =  Get-ChildItem -Path $replacer_settings_path
foreach ($filename in $filenames) {
    $setting_list += AnalyzeFile($filename)
}

# 現在の設定を一覧表示
$i = 0
ForEach($item in $setting_list) {
    $local:filename = $item.filename
    $local:summary = $item.summary
    Write-Output "  [$i]: $local:filename"
    Write-Output "    $local:summary"
    $i += 1
}

# 番号選択
$choice = ""
while($choice.GetType().Name -ne "Int32") {
    $choice = Read-Host "Select Number of list"
    try {
        if ([int]$choice -gt $setting_list.Length - 1) {
            throw "too big"
        }
        $choice = [int]$choice
    } catch {
        Write-Output "$choice is cannot recoginize for index of setting list. Use number n inside [n]"
    }
}
$selected_startup_file_path = $setting_list[$choice].filename

# ファイルバックアップ
try {
    Copy-Item $original_startup_file_path "startup.cfg.backup"
} catch {
    Write-Output "Could't backup original file: Can't find path $original_startup_file_path"
    exit
}

# 選んだファイルで置き換え
try {
    Copy-Item $selected_startup_file_path $original_startup_file_path
} catch {
    Write-Output "Couldn't replace setting file: Can't find path $selected_startup_file_path"
    exit
}

# il2 boS 実行

try{
    $proc = Start-Process $original_exe_file_path $il2args -PassThru -Wait
    write-host $proc.ExitCode
} catch {
    Write-Output "Failed to execute $original_exe_file_path."
} finally {
    $proc.Close()
}

# restore from backup
try {
    Copy-Item "startup.cfg.backup" $original_startup_file_path
} catch {
    Write-Output "Couldn't replace setting file: Can't find path $selected_startup_file_path"
    Write-Output "Pleaseestore setting file from 'startup.cfg.backup'."
    exit
}
