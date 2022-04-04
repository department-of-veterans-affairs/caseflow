require "bundler"
Bundler.require :default, :development

def fixture(local_path)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', local_path))
end
