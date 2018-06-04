Constants = Module.new

Dir.glob(File.join(Rails.root, "client", "constants", "*")).each do |filepath|
  constant_name = filepath.split("/").last.split(".").first
  Constants.const_set(constant_name.to_s, JSON.parse(File.read(filepath)))
end
