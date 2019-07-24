# frozen_string_literal: true

class HigherLevelReviewRequest::Reference < HigherLevelReviewRequest::Notes
  attr_reader :id

  def initialize(options)
    @id = options[:id]
    fail ArgumentError, "must have an id" if id.blank?
  end
end
