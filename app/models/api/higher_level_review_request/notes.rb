# frozen_string_literal: true

class HigherLevelReviewRequest::Notes
  attr_reader :notes

  def initialize(options)
    @notes = options[:notes]
    fail ArgumentError, "notes must be a string" unless notes.nil? || notes.is_a?(String)
  end
end
