# frozen_string_literal: true

# HashPathValidator is for dead simple validation of a Hash.
# It allows you to test whether or not a *single* path in a hash is within
# a set of allowed values, and provides an error description for when it's not.
#
# The validation it performs boils down to one line:
#   allowed_values.any? { |av| av === hash.dig(*path) }
#
# To see an example of how it can be used to validate an entire params object,
# see #types_and_paths and #describe_shape_error in Api::V3::DecisionReview::IntakeParams
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
#       allowed_values: ["salad", "wine"]  #### pasta left out
#     )
#
#     v.path_is_valid? # false
#
#     puts v.error_msg
#     # ["a"][0]["b"]["c"] should be one of ["salad", "wine"]. Got: "pasta".
#
#
# NOTE:
# path_is_valid? uses ===, therefore you can test the /type/ of the value at path
#
# examples:
#
#     v = Api::V3::DecisionReview::HashPathValidator.new(
#       hash: {a: {b: 44.78}},
#       path: [:a, :b],
#       allowed_values: [String, Integer]
#     )
#
#     v.path_is_valid? # false
#
#     puts v.error_msg
#     # [:a][:b] should be one of [String, Integer]. Got: 44.4.

class Api::V3::DecisionReview::HashPathValidator
  def initialize(hash:, path:, allowed_values:)
    @hash = hash
    @path = path
    @allowed_values = allowed_values
  end

  # may throw exception --use path_is_valid? first
  def dig
    hash.dig(*path)
  end

  def path_is_valid?
    @path_is_valid ||= determine_if_path_is_valid
  end

  def error_msg
    return nil if path_is_valid?

    "#{path_string} should be #{allowed_values_string}. #{dig_string}."
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

    return "a(n) #{allowed_value.name.camelize(:lower)}" if allowed_value_is_a_class?

    allowed_value.inspect
  end

  private

  attr_reader :hash, :path, :allowed_values

  # rubocop:disable Style/CaseEquality
  def determine_if_path_is_valid
    allowed_values.any? { |av| av === dig }
  rescue StandardError
    false
  end
  # rubocop:enable Style/CaseEquality

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
