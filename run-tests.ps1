Set-Location $PSScriptRoot

$env:Path = "C:\ProgramData\mingw64\mingw64\bin;$env:Path"
$env:LUA_PATH = 'C:\Users\User\AppData\Roaming\luarocks\share\lua\5.1\?.lua;C:\Users\User\AppData\Roaming\luarocks\share\lua\5.1\?\init.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\share\lua\5.1\?.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\share\lua\5.1\?\init.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\lua\?.lua;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\lua\?\init.lua;.\?.lua'
$env:LUA_CPATH = 'C:\Users\User\AppData\Roaming\luarocks\lib\lua\5.1\?.dll;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\systree\lib\lua\5.1\?.dll;C:\ProgramData\chocolatey\lib\luarocks\luarocks-2.4.4-win32\clibs\?.dll;.\?.dll'

$specs = Get-ChildItem -Path "spec" -Recurse -Filter "*_spec.lua"

$failed = $false
foreach ($spec in $specs) {
	$relative = $spec.FullName.Substring($PWD.Path.Length + 1)
	Write-Output "== $relative =="
	lua5.1 $spec.FullName
	if ($LASTEXITCODE -ne 0) { $failed = $true }
	Write-Output ""
}

if ($failed) {
	Write-Output "FAILED"
	exit 1
}

Write-Output "ALL PASSED"
