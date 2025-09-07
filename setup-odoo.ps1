param(
    [string]$Destination,
    [int]$Port = 10018,
    [int]$Chat = 20018
)

if (-not $Destination) {
    Write-Error "You must provide a destination folder name."
    exit 1
}

# Ensure path is relative to current working directory
$Destination = Join-Path -Path (Get-Location) -ChildPath $Destination

# --- Clone repo ---
git clone --depth=1 https://github.com/sandial1/odoo-18-docker-compose $Destination
Remove-Item -Recurse -Force (Join-Path $Destination ".git")

# --- Create PostgreSQL directory ---
$pgPath = Join-Path $Destination "postgresql"
if (-not (Test-Path $pgPath)) {
    New-Item -ItemType Directory -Path $pgPath | Out-Null
}

# --- Permissions ---
if ($IsLinux -or $IsMacOS) {
    & sudo chown -R $env:USER:$env:USER $Destination
    & sudo chmod -R 700 $Destination
}
elseif ($IsWindows) {
    Write-Host "Configuring Windows ACLs..."
    # Remove inheritance and reset permissions on root
    icacls $Destination /inheritance:r /grant:r "$($env:UserName):(F)" /T
}

# --- Linux/macOS sysctl configuration ---
if ($IsLinux) {
    $sysctlConf = "/etc/sysctl.conf"
    $setting = "fs.inotify.max_user_watches = 524288"

    if (-not (Select-String -Path $sysctlConf -Pattern "fs.inotify.max_user_watches" -Quiet)) {
        $setting | sudo tee -a $sysctlConf | Out-Null
    }
    sudo sysctl -p | Out-Null
}
elseif ($IsMacOS) {
    Write-Host "Running on macOS. Skipping inotify configuration."
}

# --- Update docker-compose.yml ---
$composeFile = Join-Path $Destination "docker-compose.yml"
(Get-Content $composeFile) `
    -replace '10018', $Port `
    -replace '20018', $Chat |
    Set-Content $composeFile

# --- Reset file/dir permissions ---
if ($IsLinux -or $IsMacOS) {
    #Get-ChildItem -Path $Destination -Recurse -File | ForEach-Object { chmod 644 $_.FullName }
    #Get-ChildItem -Path $Destination -Recurse -Directory | ForEach-Object { chmod 700 $_.FullName }	
    #chmod +x (Join-Path $Destination "entrypoint.sh")
	Get-ChildItem -Path $Destination -Recurse -File | ForEach-Object { chmod 777 $_.FullName }
    Get-ChildItem -Path $Destination -Recurse -Directory | ForEach-Object { chmod 777 $_.FullName }
	chmod +777 (Join-Path $Destination "entrypoint.sh")
}
elseif ($IsWindows) {
    # Files: read/write for user only
    Get-ChildItem -Path $Destination -Recurse -File | ForEach-Object {
        #icacls $_.FullName /inheritance:r /grant:r "$($env:UserName):(R,W)"
		icacls $_.FullName /inheritance:r /grant:r "$($env:UserName):(F)"
    }
    # Directories: full control for user
    Get-ChildItem -Path $Destination -Recurse -Directory | ForEach-Object {
        icacls $_.FullName /inheritance:r /grant:r "$($env:UserName):(F)"
    }
}

# --- Run docker compose ---
$composeCmd = if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    "docker-compose"
} else {
    "docker compose"
}

& $composeCmd -f $composeFile up -d

Write-Host "Odoo started at http://localhost:$Port | Master Password: minhng.info | Live chat port: $Chat"