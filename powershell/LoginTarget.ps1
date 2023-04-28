param(
  [string] $TargetIqn,
  [string] $TargetHostname,
  [string] $TargetPort,
  [int] $NumSessions = 2
)

  $succeeded = 1
  iscsicli AddTarget $TargetIqn * $TargetHostname $TargetPort * 0 * * * * * * * * * 0
  while ($succeeded -le $NumSessions)
  {
    Write-Host "Logging session ${succeeded}/${NumSessions} into ${TargetIqn}"
    $LoginOptions = '*'
    Write-Host "Enabled Multipath"
    $LoginOptions = '0x00000002'
    # PersistentLoginTarget will not establish login to the target until after the system is rebooted.
    # Use LoginTarget if the target is needed before rebooting. Using just LoginTarget will not persist the
    # session(s).
    iscsicli PersistentLoginTarget $TargetIqn t $TargetHostname $TargetPort Root\ISCSIPRT\0000_0 -1 * $LoginOptions * * * * * * * * * 0
    iscsicli LoginTarget $TargetIqn t $TargetHostname $TargetPort Root\ISCSIPRT\0000_0 -1 * $LoginOptions * * * * * * * * * 0
    if ($LASTEXITCODE -eq 0)
    {
        $succeeded += 1
    }
    Start-Sleep -s 1
    Write-Host ""
  }
