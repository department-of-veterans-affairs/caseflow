# frozen_string_literal: true

module Api::V3::Concerns::Validation
  extend ActiveSupport::Concern
  include Api::V3::Concerns::Helpers

  private

  def int?(value, name_of_value: nil, exception: ArgumentError)
    return true if !value.nil? && value == to_int(value)

    fail(exception, join_present(name_of_value, "isn't an int: <#{value}>")) if exception

    false
  end

  def int_greater_than_zero?(value, name_of_value: nil, exception: ArgumentError)
    raise_exception_with_message = -> do
      fail exception, join_present(name_of_value, "isn't an int greater than zero: <#{value}>")
    end
    
    unless int? value, exception: nil
      raise_exception_with_message[] if exception
      return false
    end
    return true if to_int(value) > 0

    raise_exception_with_message[] if exception
    false
  end

  def int_or_int_string?(value, name_of_value: nil, exception: ArgumentError)
    return true if int?(value, exception: nil) || (to_int(value) && to_int(value) == to_float(value))

    message = "is neither an int nor a string that can be converted to an int: <#{value}>"
    exception ? fail(exception, join_present(name_of_value, message)) : false
  end

  def string?(value, name_of_value: nil, exception: ArgumentError)
    value.is_a?(String) || (
      exception ? fail(exception, join_present(name_of_value, "is not a string: <#{value}>")) : false
    )
  end

  def nullable_string?(value, name_of_value: nil, exception: ArgumentError)
    value.nil? || string?(value, name_of_value: name_of_value, exception: exception)
  end

  def boolean?(value, name_of_value: nil, exception: ArgumentError)
    return true if value.is_a?(TrueClass) || value.is_a?(FalseClass)
    fail exception, join_present(name_of_value, "is not a boolean: <#{value}>") if exception

    false
  end

  def true?(value, name_of_value: nil, exception: ArgumentError)
    (value == true) || (exception ? fail(exception, join_present(name_of_value, "is not true: <#{value}>")) : false)
  end
end
