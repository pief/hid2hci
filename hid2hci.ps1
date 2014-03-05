#
# hid2hci.ps1
# Copyright (c) 2014 Pieter Hollants <pieter@hollants.com>
#
# Powershell script to automatically run hid2hci.exe when a
# USB bluetooth bluetooth adapter running in HID proxy mode
# is inserted (such as the DLink DBT-120 flashed with Apple's
# firmware update).
#
# This script works with temporary event registrations and an
# endless loop. I also developed a MOF file establishing
# permanent registrations but these didn't work reliably after
# system reboot.
#

# The USB bluetooth adapter's vendor and product IDs when in
# HID mode. See your adapter's "Properties" pane in Windows'
# device manager to find out whether you need to change these.
$USBVendorID = "0A12"
$USBProductID = "1000"

# Make MsgBox() available
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

# Remove any left-over event handlers
Get-EventSubscriber | Unregister-Event
Get-Event | Remove-Event

# Register an event handler when the DBT-120
$query = @" 
 SELECT * FROM __InstanceCreationEvent WITHIN 1
 WHERE TargetInstance ISA 'Win32_PNPEntity'
 AND TargetInstance.PNPDeviceID LIKE 'HID\\VID_${USBVendorID}&PID_${USBProductID}&%'
"@
Register-WmiEvent -Query $query -SourceIdentifier "USBDevicePluginEvent"

# Loop endlessly
for (;;) {
  # Wait for an insertion event to happen
  $event = Wait-Event -SourceIdentifier "USBDevicePluginEvent"

  # Run hid2hci.exe
  try {
    $proc = Start-Process "hid2hci.exe" -Wait -PassThru
  }
  catch {
    [System.Windows.Forms.MessageBox]::Show(
      $($_.Exception.Message),
      "hid2hci.exe",
      0,
      [System.Windows.Forms.MessageBoxIcon]::Error
    ) 
  }

  # Event has been handled
  Remove-Event -SourceIdentifier "USBDevicePluginEvent"
}
