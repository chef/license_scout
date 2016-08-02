require "bundler"
require "pry"

POSSIBLE_LICENSE_FILES = %w{LICENSE LICENSE.txt MIT-LICENSE LICENSE.MIT LGPL-2.1 LICENSE.md License.rdoc Licence.md MIT-LICENSE.txt Licence.rdoc}

source_path = "/Users/serdar/chef/github/chef"

Dir.chdir(source_path) do
  gemfile_path = File.join(source_path, "Gemfile")
  lockfile_path = File.join(source_path, "Gemfile.lock")
  d = Bundler::Definition.build(gemfile_path, lockfile_path, nil)

  problematic_license_count = 0
  total_gem_count = 0

  d.specs_for(d.groups).each do |gem_spec|
    puts "Gem is at: #{gem_spec.full_gem_path}."
    puts "Reported license is: #{gem_spec.license}"

    license_file = nil
    POSSIBLE_LICENSE_FILES.each do |l|
      if File.exists?(File.join(gem_spec.full_gem_path, l))
        license_file = l
        break
      end
    end

    total_gem_count += 1
    if license_file.nil?
      puts "======"
      puts "existing files"
      puts `ls #{gem_spec.full_gem_path}`
      puts "======"
      problematic_license_count += 1
    else
      puts "License found at #{license_file}."
    end
  end

  puts "#{problematic_license_count} / #{total_gem_count} dependencies have license issues."
end

# json (multiple license files)
# == License
#
# Ruby License, see the COPYING file included in the source distribution. The
# Ruby License includes the GNU General Public License (GPL), Version 2, so see
# the file GPL as well.

# debug_inspector (embedded in README)
# (The MIT License)
#
# Copyright (c) 2012 (John Mair)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# bundler-audit (?)
# License
# Copyright (c) 2013-2016 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# bundler-audit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bundler-audit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bundler-audit.  If not, see <http://www.gnu.org/licenses/>.
#
# [Ruby]: https://ruby-lang.org
# [RubyGems]: https://rubygems.org
# [thor]: http://whatisthor.com/
# [bundler]: https://github.com/carlhuda/bundler#readme
#
# [OSVDB]: http://osvdb.org/
# [ruby-advisory-db]: https://github.com/rubysec/ruby-advisory-db
