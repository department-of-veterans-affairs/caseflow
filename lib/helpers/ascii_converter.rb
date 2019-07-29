require "stringex/unidecoder"
require "stringex/core_ext"

class AsciiConverter
  def initialize(string:)
    @str = string
  end

  def convert
    return str if ascii?
    return str.encode("UTF-8", "Windows-1252").to_ascii if cp1252?
    return str.to_ascii
  end

  private

  attr_reader :str

  def ascii?
    !str.bytes.any? { |byte| byte > 127 }
  end

  def cp1252?
    (str.bytes & Array(128..159)).any?
  end
end
