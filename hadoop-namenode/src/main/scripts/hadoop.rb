require 'base_hadoop'

class HadoopLauncher < BaseHadoopLauncher
  def run_custom_setup
    super

    data_dir = @options[:data_dir]
    dfs_name_dir = File.join(data_dir, 'dfs', 'name')

    interpolate_config('hdfs-site.xml', {
      'dfs.name.dir' => dfs_name_dir,
    })

    run_hadoop_command('namenode', '-format') unless File.exist?(dfs_name_dir)
  end

  def build_hadoop_command(hadoop)
    [hadoop, 'namenode']
  end
end
