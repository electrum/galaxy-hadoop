require 'base_hadoop'

class HadoopLauncher < BaseHadoopLauncher
  def build_hadoop_command(hadoop)
    [hadoop, 'version']
  end
end
