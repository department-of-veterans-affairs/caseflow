# frozen_string_literal: true

class TextAnalyzerService
  def initialize(comprehend_client)
    @comprehend_client = comprehend_client
  end

  def analyze(text)
    return [] if text.nil? || text.empty?
    @comprehend_client.detect_entities(text: text, language_code: 'en')
  end
end
