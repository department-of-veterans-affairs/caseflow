# frozen_string_literal: true

class Api::V3::DecisionReview::Params
  include Api::V3::DecisionReview::ValidatableHash

  attr_reader :hash, :errors

  def hash_path
    class_name_elements = self.class.name.split("::")
    index_of_element_ending_in_params = class_name_elements.index { |el| el =~ /Params$/ }

    index_of_element_ending_in_params &&
      class_name_elements[(index_of_element_ending_in_params + 1)..-1]
  end

  def hash_path_str
    hash_path.map { |str| "[\"#{str.camelize(:lower)}\"]" }.join
  end
end
