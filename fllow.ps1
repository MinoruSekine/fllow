class ShortcutsEnumerator {
    [String[]]EnumerateShortcuts([String]$EnumRootPath) {
	return (Get-ChildItem -Path $EnumRootPath | where {$_.extension -eq ".lnk"}).FullName
    }
}

class ApplicationLaunchConfiguration {
    [String]$ShortcutPath
    [TimeSpan]$TimeoutDuration
    [Float]$CpuUsageThreshold

    ApplicationLaunchConfiguration([String]$ShortcutPath) {
	$this.ShortcutPath = $ShortcutPath
	$this.TimeoutDuration = New-TimeSpan -Seconds 90
	$this.CpuUsageThreshold = 0.5
    }
}

class CpuUsageWatcher {
    [Float]GetCurrentCpuUsage() {
	return [Float](Get-WmiObject Win32_Processor).LoadPercentage / 100.0
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
	foreach($applicationLaunchConfiguration in $ApplicationLaunchConfigurations) {
	    $timeoutChecker = [TimeoutChecker]::new()
	    $timeoutChecker.Start($applicationLaunchConfiguration.TimeoutDuration)
	    while(-not $timeoutChecker.HasBeenTimeout()) {
		$cpuUsageCheckIntervalSec = 0.5
		Start-Sleep -Seconds $cpuUsageCheckIntervalSec
		$cpuUsageWatcher = [CpuUsageWatcher]::new()
	        if($cpuUsageWatcher.GetCurrentCpuUsage() -le $applicationLaunchConfiguration.CpuUsageThreshold) {
		    break
		}
	    }
	    $applicationLauncher = [ApplicationLauncher]::new()
	    $applicationLauncher.InvokeShortcut($applicationLaunchConfiguration.ShortcutPath)
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


