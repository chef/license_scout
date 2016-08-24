#
# Cookbook Name:: windows-sdk
# Recipe:: wpt
#
# Copyright (c) 2015 Chef Software, All Rights Reserved.

windows_sdk_feature :windows_performance_toolkit do
  install_path node["windows-sdk"]["install_path"]
end
