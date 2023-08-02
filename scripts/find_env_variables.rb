# frozen_string_literal: true

# bundle exec rails runner scripts/find_env_variables.rb

class FindEnvVariables
  def call
    files.each_with_object([]) do |file, result|
      result << EnvVariablesSearch.new(file: file, regex: env_variable_regex).call
    end
  end

  private

  def files
    app_rb_files + app_erb_files + config_files + script_files + lib_files
  end

  def app_rb_files
    Dir.glob("app/**/*.rb")
  end

  def app_erb_files
    Dir.glob("app/views/**/*.erb")
  end

  def config_files
    Dir.glob("config/**/*.*")
  end

  def lib_files
    Dir.glob("lib/**/*.rb")
  end

  def script_files
    Dir.glob("scripts/**/*.*")
  end

  def env_variable_regex
    /ENV\[\".+\"\]/
  end
end

class EnvVariablesSearch
  def initialize(file:, regex:)
    @file = file
    @regex = regex
  end

  def call
    File.open(file, "r").each_with_object([]) do |line, result|
      line.match(regex) do |found|
        result << found[0]
      end
    end
  end

  private

  attr_reader :file, :regex
end

all_env_variables = FindEnvVariables.new.call.flatten.uniq
all_env_variables.map! { |env| env.split(" ").flatten }.flatten!
all_env_variables.reject! { |env| ['?', '||', 'if'].include?(env) && !env.include?('ENV["')}
all_env_variables.map! { |env|  env.gsub(/ENV\[\"/, '').gsub(/\"\]/, '') }.flatten!

puts all_env_variables.uniq.sort
