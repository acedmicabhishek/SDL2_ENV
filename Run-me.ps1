# paths
$MinGWSource = ".\MinGW"
$MinGWTarget = "C:\MinGW"
$PythonInstallerUrl = "https://www.python.org/ftp/python/3.10.0/python-3.10.0-amd64.exe"
$PythonInstallerPath = "$env:TEMP\python_installer.exe"
$PythonScript = ".\sdl_setup_script.py"

# Step 1: Copy MinGW to C:\
Write-Host "Copying MinGW to C:\..."
if (Test-Path -Path $MinGWSource) {
    Copy-Item -Path $MinGWSource -Destination $MinGWTarget -Recurse -Force
    Write-Host "MinGW copied successfully."
} else {
    Write-Host "Error: MinGW folder not found in the current directory."
    exit 1
}

# Step 2: Set the environment variable for MinGW
Write-Host "Setting up environment variable for MinGW..."
$Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
if ($Path -notlike "*C:\MinGW\bin*") {
    [System.Environment]::SetEnvironmentVariable("Path", "$Path;C:\MinGW\bin", "Machine")
    Write-Host "Environment variable set successfully."
} else {
    Write-Host "Environment variable already set."
}

# Step 3: Checker if Python is installed, and install it if not
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "Python not found. Downloading and installing Python..."
    
    # Download Python installer
    Invoke-WebRequest -Uri $PythonInstallerUrl -OutFile $PythonInstallerPath

    # Install Python silently
    Start-Process -FilePath $PythonInstallerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

    # Remove the installer after installation
    Remove-Item -Path $PythonInstallerPath -Force
    Write-Host "Python installed successfully."
} else {
    Write-Host "Python is already installed."
}

# Step 4: Run the SDL setup script
if (Test-Path -Path $PythonScript) {
    Write-Host "Running SDL setup script..."
    python $PythonScript
} else {
    Write-Host "Error: sdl_setup_script.py not found in the current directory."
    exit 1
}

Write-Host "Setup complete."

$null = Read-Host "Press Enter to close the program"
