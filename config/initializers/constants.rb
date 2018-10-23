Constants = Module.new

Dir.glob(File.join(Rails.root, "client", "constants", "*")).each do |filepath|
  constant_name = filepath.split("/").last.split(".").first
  file_contents = JSON.parse(File.read(filepath))

  # Access via hash (Constants::BENEFIT_TYPES["compensation"]) to access keys.
  Constants.const_set(constant_name.to_s, file_contents)

  # Access via methods (Constants.BENEFIT_TYPES.compensation) to throw errors when incorrectly addressing constants.
  Constants.define_singleton_method(constant_name) { Subconstant.new(file_contents) }
end

# https://stackoverflow.com/questions/26809848/convert-hash-to-object
class Subconstant
  def initialize(hash)
    hash.each do |k, v|
      define_singleton_method(k) { v.is_a?(Hash) ? Subconstant.new(v) : v }
    end
  end

  def to_h
    h = {}
    singleton_methods.each do |m|
      val = singleton_method(m).call
      h[m] = val.is_a?(Subconstant) ? val.to_h : val
    end
    h
  end
end
