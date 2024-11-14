# frozen_string_literal: true

# Custom column types, particularly for VACOLS

require "helpers/ascii_converter"

class AsciiString < ActiveRecord::Type::Text
  private

  def cast_value(value)
    ascii_value = AsciiConverter.new(string: value.to_s).convert
    limit ? ascii_value[0, limit] : ascii_value
  end
end

ActiveRecord::Type.register(:ascii_string, AsciiString)
