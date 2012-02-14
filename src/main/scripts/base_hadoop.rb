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
    jvm_properties = Launch::Properties.try_load_lines(@options[:jvm_config_path]).join(' ')

    @options[:system_properties].each do |k, v|
      if Launch::Util.escape_shell_arg(v) != v
        raise "Escaping required but not supported for system property: #{k}=#{v}"
      end
    end
    system_properties = @options[:system_properties].map { |k, v| "-D#{k}=#{v}" }.join(' ')

    @options[:environment]['HADOOP_OPTS'] = "#{jvm_properties} #{system_properties}"
  end

  def force_symlink(src, dest)
    return if src == dest
    if File.exists?(dest) && !File.symlink?(dest)
      raise "Destination exists and is not a symlink: #{dest}"
    end
    File.delete(dest) rescue nil
    File.symlink(src, dest)
  end

  def symlink_install_dirs(*dirs)
    dirs.each do |dir|
      force_symlink(File.join(@install_path, dir), File.join(@options[:data_dir], dir))
    end
  end

  def run_custom_setup
    symlink_install_dirs('bin', 'conf', 'contrib', 'lib', 'webapps')

    inventory = Launch::ServiceInventory.new(@options)
    hdfs = inventory.properties('hadoop-namenode')['hdfs']
    raise 'No HDFS property for namenode service' unless hdfs

    interpolate_config('core-site.xml', {
      'namenode.hdfs.uri' => hdfs,
    })
  end

  def build_command_line(daemon)
    hadoop = File.join(@install_path, 'bin', 'hadoop')
    build_hadoop_command(hadoop)
  end

  def build_hadoop_command(hadoop)
    throw NotImplementedError
  end

  def run_hadoop_command(*command)
    hadoop = File.join(@install_path, 'bin', 'hadoop')
    command = [hadoop] + command

    Pathname.new(@options[:log_path]).dirname.mkpath

    pid = Process.spawn(@options[:environment],
                        *command,
                        :chdir => @options[:data_dir],
                        :umask => 0027,
                        :in => '/dev/null',
                        :out => [@options[:log_path], "a"],
                        :err => [:child, :out],
                        :unsetenv_others => true,
                        :pgroup => true)
    Process.wait(pid)
  end

  def interpolate_config(name, vars)
    path = File.join(@install_path, 'etc', name)
    raise Launch::CommandError.new(:config_missing, "Config file is missing: #{path}") unless File.exists?(path)
    config = IO.read(path)

    vars.each do |key, value|
      var = "\#{#{key}}"
      unless config.include?(var)
        raise Launch::CommandError.new(:config_missing, "Replacement variable #{var} not found in file: #{path}")
      end
      config = config.gsub(var, value)
    end

    out = File.join(@options[:data_dir], 'conf', name)
    File.open(out, 'w') { |f| f.write(config) }
  end
end
