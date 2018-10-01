Constants = Module.new

Dir.glob(File.join(Rails.root, "client", "constants", "*")).each do |filepath|
  constant_name = filepath.split("/").last.split(".").first
  file_contents = JSON.parse(File.read(filepath))

  # Access Constants through hash: Constants::BENEFIT_TYPES["compensation"]
  Constants.const_set(constant_name.to_s, file_contents)

  # Access Constants through object: Constants.BENEFIT_TYPES.compensation
  Constants.define_singleton_method(constant_name) { Subconstant.new(file_contents) }
end

# https://stackoverflow.com/questions/26809848/convert-hash-to-object
class Subconstant
  def initialize(hash)
    hash.each do |k, v|
      define_singleton_method(k) { v.is_a?(Hash) ? Subconstant.new(v) : v }
    end
  end
end
