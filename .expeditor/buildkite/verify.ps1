echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# Install winrm
winrm quickconfig -q

# Install cmake
choco install cmake
$Env:path += ";C:\Program Files\CMake\bin"

gem update bundler --no-document

echo "--- Print Runtime Environment"
echo $Env:path
ruby -v
bundle --version
bundle config set path 'vendor/bundle'
bundle env

echo "--- bundle install"
bundle install

echo "+++ bundle exec rake"
bundle exec rake spec

exit $LASTEXITCODE