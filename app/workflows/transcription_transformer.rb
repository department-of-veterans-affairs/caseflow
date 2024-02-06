# frozen_string_literal: true

class TranscriptionTransformer
  class FileConversionError < StandardError; end

  def initialize(file_path)
    @file_path = file_path
  end

  def call; end
end
