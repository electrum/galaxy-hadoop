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

require 'fileutils'
require 'pathname'
require 'launch'

class BaseHadoopLauncher < Launch::AbstractLauncher
  def initialize(file)
    super(file)

    @options[:jvm_config_path] = File.join(@install_path, 'etc', 'jvm.config')
    @options[:system_properties] = {}
  end

  def add_custom_options(opts)
    opts.on('--jvm-config FILE', 'Defaults to INSTALL_PATH/etc/jvm.config') do |v|
      @options[:jvm_config_path] = File.expand_path(v)
    end

    opts.on('-D<name>=<value>', 'Sets a Java System property') do |v|
      key, value = v.split('=', 2).map(&:strip)
      @options[:system_properties][key] = value
    end
  end

  def finalize_options
    @options[:system_properties].merge!(@options[:node_properties])

    jvm_properties = Launch::Properties.try_load_lines(@options[:jvm_config_path]).join(' ')

    system_properties = @options[:system_properties].
      map { |k, v| "-D#{k}=#{v}" }.
      map { |v| escape_shell_arg(v) }.
      join(' ')

    @options[:environment]['HADOOP_OPTS'] = "#{jvm_properties} #{system_properties}"
  end

  def build_command_line(daemon)
    hadoop = File.join(@install_path, 'bin', 'hadoop')
    build_hadoop_command(hadoop)
  end

  def build_hadoop_command(hadoop)
    throw NotImplementedError
  end
end
