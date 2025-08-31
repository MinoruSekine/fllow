# fllow

`fllow` is a PowerShell script
to support "Fluent log on to Windows"
or "Fluent launching apps on Windows".
`fllow` starts registered apps' shortcuts sequentially
without CPU usage overloads.

## Usage

### Basic usage

1. Put `fllow.ps1` to your folder
1. Create sub-folder `01_shortcuts` under the folder which has `fllow.ps1`
1. Put shortcuts to launch into `01_shortcuts`

And invoke `fllow.ps1` by PowerShell.
Applications which have put their shortcuts into `01_shortcuts`
will be launched sequentially without CPU usage overloads.

It can be improve your logon experience
to put application shortcuts into `01_shortcuts`
instead of your startup folder and
register `fllow.ps1` to your startup folder.

## License

Distributed under GNU Affero General Public License version 3.
See [LICENSE](/LICENSE).
