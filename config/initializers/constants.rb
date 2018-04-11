Constants = Object.new

Dir.glob(File.join(Rails.root, "constants", "*")).each do |filename|
  constant_name = filename.split("/").last.split(".").first
  Constants.define_singleton_method("#{constant_name}") { JSON.parse(File.read(filename)) }
end
