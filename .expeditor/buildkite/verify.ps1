echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize
winrm quickconfig -q
ruby -v
bundle --version

echo "--- bundle install"
bundle install

echo "+++ bundle exec rake"
bundle exec rake spec

exit $LASTEXITCODE