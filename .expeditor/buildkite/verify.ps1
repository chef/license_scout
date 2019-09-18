echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# Install winrm
winrm quickconfig -q

# Install cmake
choco install cmake
$Env:path += ";C:\Program Files\CMake\bin"

echo $Env:path

gem update bundler

ruby -v
bundle --version

echo "--- bundle install"
bundle install

echo "+++ bundle exec rake"
bundle exec rake spec

exit $LASTEXITCODE