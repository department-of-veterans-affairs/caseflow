# Custom column types, particularly for VACOLS

require "stringex/unidecoder"
require "stringex/core_ext"

class AsciiString < ActiveRecord::Type::String
  private

  def cast_value(value)
    limit ? value.to_s.to_ascii[0, limit-1] : value.to_s.to_ascii
  end
end

ActiveRecord::Type.register(:ascii_string, AsciiString)
