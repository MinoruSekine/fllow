[CmdletBinding()]
param()

class ShortcutsEnumerator {
    [String[]]EnumerateShortcuts([String]$EnumRootPath) {
	return (Get-ChildItem -Path $EnumRootPath | Where-Object {$_.extension -eq ".lnk"}).FullName | Sort-Object
    }
}

class ApplicationLaunchConfiguration {
    [String]$ShortcutPath
    [TimeSpan]$TimeoutDuration
    [Float]$CpuUsageThreshold
    [TimeSpan]$WaitForNextLaunch

    ApplicationLaunchConfiguration([String]$ShortcutPath) {
	$this.ShortcutPath = $ShortcutPath
	$this.TimeoutDuration = New-TimeSpan -Seconds 180
	$this.CpuUsageThreshold = $this.GetDefaultCpuUsageThreshold()
	$this.WaitForNextLaunch = New-TimeSpan -Seconds 4
    }

    [UInt32]GetNumOfIdleCoresToLaunchNext([UInt32]$NumOfLocicalProcessors) {
	[UInt32]$NumOfIdleCoresToLaunchNext = [math]::log($NumOfLocicalProcessors, 2)
	if ($NumOfIdleCoresToLaunchNext -le 2) {
	    $NumOfIdleCoresToLaunchNext = 1
	} else {
	    $NumOfIdleCoresToLaunchNext -= 1
	}
	return $NumOfIdleCoresToLaunchNext
    }

    [Float]GetDefaultCpuUsageThreshold() {
	[UInt32]$NumOfCores = ((Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors)
	[UInt32]$NumOfCoresForIdle = $this.GetNumOfIdleCoresToLaunchNext($NumOfCores)
	[Float]$threshold = (1.0 - (([Float]$NumOfCoresForIdle) / $NumOfCores))
	if ($threshold -le 0.0 -Or $threshold -ge 1.0) {
	    $threshold = 0.75  # Fallback default value for unexepected num of cores.
	}
	return $threshold
    }
}

class CpuUsageWatcher {
    [Float]GetCurrentCpuUsage() {
	return [Float]((Get-CimInstance -ClassName Win32_Processor).LoadPercentage) / 100.0
    }
}

class TimeoutChecker {
    [DateTime]$TimeoutDateTime

    [Void]Start([TimeSpan]$TimeoutDuration) {
	$now = Get-Date
	$this.TimeoutDateTime = $now + $TimeoutDuration
    }

    [Bool]HasBeenTimeout() {
	$now = Get-Date
	return $now -ge $this.TimeoutDateTime
    }
}

class ConfigurationBuilder {
    [ApplicationLaunchConfiguration[]]BuildApplicationLaunchConfig([String]$ShortcutsDirectoryPath) {
	$shortcutsEnumerator = [ShortcutsEnumerator]::new()
	$shortcuts = $shortcutsEnumerator.EnumerateShortcuts($ShortcutsDirectoryPath)
	$applicationLaunchConfigurations = @()
	foreach($shortcut in $shortcuts) {
	    $applicationLaunchConfigurations += [ApplicationLaunchConfiguration]::new($shortcut)
	}
	return $applicationLaunchConfigurations
    }
}

class ApplicationLauncher {
    [Void]InvokeShortcut([String]$ShortcutPath) {
	Invoke-Item $ShortcutPath
    }
}

class FluentLauncher {
    [Void]LaunchFluently([ApplicationLaunchConfiguration[]]$ApplicationLaunchConfigurations) {
	$intervalChecker = $null
	foreach($applicationLaunchConfiguration in $ApplicationLaunchConfigurations) {
	    $timeoutChecker = [TimeoutChecker]::new()
	    $timeoutChecker.Start($applicationLaunchConfiguration.TimeoutDuration)
	    while(-not $timeoutChecker.HasBeenTimeout()) {
		$cpuUsageCheckIntervalSec = 0.6
		Start-Sleep -Seconds $cpuUsageCheckIntervalSec
		if (($null -ne $intervalChecker) -And (-not $intervalChecker.HasBeenTimeout())) {
		    Write-Verbose "$((Get-Date).ToString()) Waiting for minimum launch interval"
		    continue
		}
		$cpuUsageWatcher = [CpuUsageWatcher]::new()
		$currentCpuUsage = $cpuUsageWatcher.GetCurrentCpuUsage()
	        if($currentCpuUsage -le $applicationLaunchConfiguration.CpuUsageThreshold) {
		    Write-Verbose "$((Get-Date).ToString()) Launching $($applicationLaunchConfiguration.ShortcutPath) (now: ${currentCpuUsage}, target: $($applicationLaunchConfiguration.CpuUsageThreshold))"
		    break
		}
		Write-Verbose "$($applicationLaunchConfiguration.ShortcutPath) is waiting for CPU idle (now: ${currentCpuUsage}, target: $($applicationLaunchConfiguration.CpuUsageThreshold))"
	    }
	    if ($timeoutChecker.HasBeenTimeout()) {
		Write-Verbose "$($applicationLaunchConfiguration.ShortcutPath) timeout exceeded ($($applicationLaunchConfiguration.TimeoutDuration))"
	    }
	    $applicationLauncher = [ApplicationLauncher]::new()
	    $applicationLauncher.InvokeShortcut($applicationLaunchConfiguration.ShortcutPath)
	    $intervalChecker = [TimeoutChecker]::new()
	    $intervalChecker.Start($applicationLaunchConfiguration.WaitForNextLaunch)
	}
    }
}

class FllowModel {
    [Void]LaunchByConfig([String]$ConfigurationDirectoryPath) {
	$configurationBuilder = [ConfigurationBuilder]::new()
	$shortcutsDirectoryPath = Join-Path $ConfigurationDirectoryPath 01_shortcuts
	$applicationLaunchConfigurations = $configurationBuilder.BuildApplicationLaunchConfig($shortcutsDirectoryPath)
	$fluentLauncher = [FluentLauncher]::new()
	$fluentLauncher.LaunchFluently($applicationLaunchConfigurations)
    }
}

$fllowModel = [FllowModel]::new()
$fllowModel.LaunchByConfig($PSScriptRoot)


