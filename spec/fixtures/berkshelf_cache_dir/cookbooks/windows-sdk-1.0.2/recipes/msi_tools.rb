#
# Cookbook Name:: windows-sdk
# Recipe:: msi_tools
#
# Copyright (c) 2015 Chef Software, All Rights Reserved.

windows_sdk_feature :msi_tools do
  install_path node["windows-sdk"]["install_path"]
end
