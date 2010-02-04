require 'rubygems'
require 'rbconfig'
require 'tempfile'
require 'spec/expectations'
require 'fileutils'
require 'forwardable'
require 'win32/process'
require 'erb'

class CucumberWorld
  extend Forwardable
  def_delegators CucumberWorld, :examples_dir, :self_test_dir, :working_dir, :lib_dir, :cuke4lua_server, :cuke4lua_wrapper_path

  def self.examples_dir(subdir=nil)
    @examples_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../examples'))
    subdir ? File.join(@examples_dir, subdir) : @examples_dir
  end

  def self.self_test_dir
    @self_test_dir ||= examples_dir('self_test')
  end

  def self.working_dir
    @working_dir ||= examples_dir('self_test/tmp')
  end

  def lib_dir
    @lib_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../lib'))
  end
  
  def lua_lib_dir
    @lua_lib_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '../../lib'))
    os = Config::CONFIG['host_os'] 
    if os =~ /mswin|mingw/ then
      @lua_lib_dir.gsub('/', '\\')
    else
      @lua_lib_dir
    end
  end
  
  def cuke4lua_server
    @cuke4lua_server ||= File.expand_path(File.join(File.dirname(__FILE__), '../../lib/cuke4lua.lua'))
  end
  
  def cuke4lua_wrapper_path
    @cuke4lua_wrapper_path ||= File.expand_path(File.join(File.dirname(__FILE__), '../../gem/bin/cuke4lua'))
  end

  def initialize
    @current_dir = self_test_dir
  end

  private
  attr_reader :last_exit_status, :last_stderr

  def build_step_definitions(contents)
    src_path = File.join(working_dir, 'src/GeneratedStepDefinitions.lua').gsub('/', '\\')
    ref_path = File.expand_path(File.join(examples_dir, '../lib/uhhhh TODO')).gsub('/', '\\')
    create_file(src_path, contents)
    src_path
  end
  
  # The last standard out, with the duration line taken out (unpredictable)
  def last_stdout
    strip_duration(@last_stdout)
  end

  def strip_duration(s)
    s.gsub(/^\d+m\d+\.\d+s\n/m, "")
  end

  def replace_duration(s, replacement)
    s.gsub(/\d+m\d+\.\d+s/m, replacement)
  end

  def replace_junit_duration(s, replacement)
    s.gsub(/\d+\.\d\d+/m, replacement)
  end

  def strip_ruby186_extra_trace(s)  
    s.gsub(/^.*\.\/features\/step_definitions(.*)\n/, "")
  end

  def create_file(file_name, file_content)
    file_content.gsub!("CUCUMBER_LIB", "'#{lib_dir}'") # Some files, such as Rakefiles need to use the lib dir
    in_current_dir do
      FileUtils.mkdir_p(File.dirname(file_name)) unless File.directory?(File.dirname(file_name))
      File.open(file_name, 'w') { |f| f << file_content }
    end
  end

  def set_env_var(variable, value)
    @original_env_vars ||= {}
    @original_env_vars[variable] = ENV[variable] 
    ENV[variable]  = value
  end

  def background_jobs
    @background_jobs ||= []
  end

  def in_current_dir(&block)
    Dir.chdir(@current_dir, &block)
  end

  def run(command)
    stderr_file = Tempfile.new('cucumber')
    stderr_file.close
    in_current_dir do
      mode = Cucumber::RUBY_1_9 ? {:external_encoding=>"UTF-8"} : 'r'
      IO.popen("#{command} 2> #{stderr_file.path}", mode) do |io|
        @last_stdout = io.read
      end

      @last_exit_status = $?.exitstatus
    end
    @last_stderr = IO.read(stderr_file.path)
  end

  def run_in_background(command)
    in_current_dir do
      process = IO.popen(command, 'r')
      background_jobs << process.pid
    end
  end

  def terminate_background_jobs
    if @background_jobs
      @background_jobs.each do |pid|
        # TODO
        #Process.kill(9, pid)
      end
    end
  end

  def restore_original_env_vars
    @original_env_vars.each { |variable, value| ENV[variable] = value } if @original_env_vars
  end

end

World do
  CucumberWorld.new
end

Before do
  FileUtils.remove_dir(CucumberWorld.working_dir) if File.exists? CucumberWorld.working_dir
  FileUtils.mkdir CucumberWorld.working_dir
end

After do
  terminate_background_jobs
  restore_original_env_vars
end
