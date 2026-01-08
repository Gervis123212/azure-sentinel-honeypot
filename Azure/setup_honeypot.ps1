# PowerShell Script to Configure Windows Honeypot VM

# This script configures a Windows VM to act as a honeypot.
# It disables Network Level Authentication (NLA) for RDP and turns off the Windows Firewall.
#
# WARNING: Running this script significantly reduces the security of the Windows machine.
# Only use this on a dedicated honeypot VM and never on a production system.

Write-Host "Starting honeypot configuration..."

# --- Disable Network Level Authentication (NLA) for RDP ---
Write-Host "Disabling Network Level Authentication (NLA) for RDP..."
try {
    # Set fUserAuthentication to 0 to disable NLA (often found under RDP-Tcp)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
        -Name "UserAuthentication" -Value 0 -ErrorAction Stop

    # Ensure fAllowSecProtocolNegotiation is set to 1 (enables RDP connections without NLA)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
        -Name "fAllowSecProtocolNegotiation" -Value 1 -ErrorAction Stop

    # Also ensure fDenyTSConnections is 0 to allow RDP connections
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
        -Name "fDenyTSConnections" -Value 0 -ErrorAction Stop

    Write-Host "NLA for RDP has been disabled successfully."
}
catch {
    Write-Error "Failed to disable NLA for RDP: $($_.Exception.Message)"
}

# --- Disable Windows Firewall ---
Write-Host "Disabling Windows Firewall for all profiles (Domain, Private, Public)..."
try {
    Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled False -ErrorAction Stop
    Write-Host "Windows Firewall has been disabled successfully."
}
catch {
    Write-Error "Failed to disable Windows Firewall: $($_.Exception.Message)"
}

Write-Host "Honeypot configuration complete. A reboot might be required for all changes to take effect."
Write-Host "You can now safely connect via RDP without NLA and all traffic should be visible."