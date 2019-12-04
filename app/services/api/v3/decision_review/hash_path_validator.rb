# frozen_string_literal: true

# given a hash, path, and an array of values
# you can ask if the value at path is valid (is one of the allowed values)
# and you can print an error message describing the failed expectation
#
# examples:
#
#     v = Api::V3::DecisionReview::HashPathValidator.new(
#       hash: {"a"=>[{"b"=>{"c"=>"pasta"}}]},
#       path: ["a", 0, "b", "c"],
#       allowed_values: ["salad", "wine", "pasta"]
#     )
#
#     v.path_is_valid? # true
#
#     puts v.error_msg # nil
#
#     v = Api::V3::DecisionReview::HashPathValidator.new(
#       hash: {"a"=>[{"b"=>{"c"=>"pasta"}}]},
#       path: ["a", 0, "b", "c"],
#       allowed_values: ["salad", "wine"]  # PASTA ISN'T AN ALLOWED VALUE
#     )
#
#     v.path_is_valid? # false
#
#     puts v.error_msg
#     # ["a"][0]["b"]["c"] should be one of ["salad", "wine"]. Got: "pasta".
#
#
# NOTE:
# path_is_valid? uses ===
# therefore you can test the /type/ of what's at path
#
# examples:
#
#     v = Api::V3::DecisionReview::HashPathValidator.new(
#       hash: {a: {b: 44.4}},
#       path: [:a, :b],
#       allowed_values: [String, Integer]
#     )
#
#     v.path_is_valid? # false
#
#     puts v.error_msg
#     # [:a][:b] should be one of [String, Integer]. Got: 44.4.
#
#     v = Api::V3::DecisionReview::HashPathValidator.new(
#       hash: {a: {b: 44}},
#       path: [:a, :b],
#       allowed_values: [String, Integer]
#     )
#
#     v.path_is_valid? # true
#
#     v.error_msg # nil

class Api::V3::DecisionReview::HashPathValidator
  def initialize(hash:, path:, allowed_values:)
    @hash = hash
    @path = path
    @allowed_values = allowed_values

    throw_exception_for_bad_input
  end

  # may throw exception --use path_is_valid? first
  def dig
    hash.dig(*path)
  end

  def path_is_valid?
    @path_is_valid ||= begin
                       allowed_values.any? { |av| av === dig }
                       rescue StandardError
                         false
                     end
  end

  def error_msg
    return nil if path_is_valid?

    "#{path_string} should be #{allowed_values_string}. #{dig_string}."
  end

  private

  attr_reader :hash, :path, :allowed_values

  def throw_exception_for_bad_input
    fail "hash must respond to :dig" unless hash.respond_to? :dig
    fail "path must be an array" unless path.is_a? Array
    fail "allowed_values must be an array" unless allowed_values.is_a? Array
  end

  def dig_string
    "Got: #{dig.inspect}"
  rescue StandardError
    "Invalid path"
  end

  def path_string
    path.map { |node| "[#{node.inspect}]" }.join
  end

  def allowed_values_string
    return "one of #{allowed_values}" unless only_one_allowed_value?

    return "a(n) #{allowed_value.name.downcase}" if allowed_value_is_a_class?

    allowed_value.inspect
  end

  def only_one_allowed_value?
    allowed_values.length == 1
  end

  def allowed_value_is_a_class?
    allowed_value.class == Class
  end

  def allowed_value
    allowed_values.first
  end
end
