# frozen_string_literal: true

Rails.application.config.before_initialize do
  # Custom column types, particularly for VACOLS

  class AsciiString < ActiveRecord::Type::Text
    private

    def cast_value(value)
      ascii_value = AsciiConverter.new(string: value.to_s).convert
      limit ? ascii_value[0, limit] : ascii_value
    end
  end

  ActiveRecord::Type.register(:ascii_string, AsciiString)
end
