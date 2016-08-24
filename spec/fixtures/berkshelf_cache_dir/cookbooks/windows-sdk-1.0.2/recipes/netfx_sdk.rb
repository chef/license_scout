#
# Cookbook Name:: windows-sdk
# Recipe:: netfx_sdk
#
# Copyright (c) 2015 Chef Software, All Rights Reserved.

windows_sdk_feature :netfx_software_development_kit do
  install_path node["windows-sdk"]["install_path"]
end
