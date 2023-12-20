# frozen_string_literal: true

require "stringex/unidecoder"
require "stringex/core_ext"

class AsciiConverter
  def initialize(string:)
    @str = string
  end

  def convert
    return str if str.ascii_only?

    return str.to_ascii if utf8?

    return str.encode("UTF-8", "Windows-1252").to_ascii if !utf8? && cp1252?

    str.to_ascii
  end

  private

  attr_reader :str

  def utf8?
    str.valid_encoding? && str.encoding == Encoding::UTF_8
  end

  def cp1252?
    (str.bytes & Array(128..159)).any?
  end
end
