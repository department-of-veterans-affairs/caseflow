# frozen_string_literal: true

Rails.application.config.before_initialize do
  # https://stackoverflow.com/questions/26809848/convert-hash-to-object
  class Subconstant
    class << self
      def build_constants_module(module_name:, path_attributes:)
        Object.const_set(module_name, Module.new)
        constants_module = Object.const_get(module_name)
        Dir.glob(File.join(Rails.root, *path_attributes)).each do |filepath|
          constant_name = filepath.split("/").last.split(".").first
          file_contents = JSON.parse(File.read(filepath))

          # Access via hash (i.e. Constants::BENEFIT_TYPES["compensation"]) to access keys.
          constants_module.const_set(constant_name.to_s, file_contents)

          # Access via methods (i.e. Constants.BENEFIT_TYPES.compensation) to throw errors
          # when incorrectly addressing constants.
          constants_module.define_singleton_method(constant_name) { Subconstant.new(file_contents) }
        end
      end
    end

    def initialize(hash_in)
      hash_in.each do |hash_key, hash_value|
        define_singleton_method(hash_key) { hash_value.is_a?(Hash) ? Subconstant.new(hash_value) : hash_value }
      end
    end

    def to_h
      hash_out = {}
      singleton_methods.each do |method_name|
        call_value = singleton_method(method_name).call
        hash_out[method_name] = call_value.is_a?(Subconstant) ? call_value.to_h : call_value
      end
      hash_out
    end
  end

  Subconstant.build_constants_module(module_name: "Constants", path_attributes: ["client", "constants", "*"])
  Subconstant.build_constants_module(module_name: "FakeConstants", path_attributes: ["lib", "fakes", "constants", "*"])
end
