echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize
winrm quickconfig -q
ruby -v
bundle --version

echo "--- bundle install"
bundle install --jobs=7 --retry=3 --without tools integration travis style omnibus_package

echo "+++ bundle exec rspec"
bundle exec rspec

exit $LASTEXITCODE