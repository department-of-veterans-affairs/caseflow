Constants = Object.new

Dir.glob(File.join(Rails.root, "constants", "*")).each do |filepath|
  constant_name = filepath.split("/").last.split(".").first
  Constants.define_singleton_method(constant_name.to_s) { JSON.parse(File.read(filepath)) }
end
