#!/usr/bin/env ruby
#
# Copyright 2010-2012 Proofpoint, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if RUBY_VERSION < "1.9" || RUBY_ENGINE != "ruby"
  puts "MRI Ruby 1.9+ is required. Current version is #{RUBY_VERSION} [#{RUBY_PLATFORM}]"
  exit 99
end

=begin

Expects config under "etc":
  node.properties
  jvm.config

Options:
  --jvm-config to override jvm config file

Logs to var/log/launcher.log when run as daemon
Logs to console when run in foreground, unless log file provided

Requires Java and Ruby to be in PATH

=end

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'hadoop'

HadoopLauncher.new(__FILE__).execute(ARGV)
