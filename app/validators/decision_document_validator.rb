# frozen_string_literal: true

module DecisionDocumentValidator
  extend ActiveSupport::Concern

  included do
    validate :unique_citation_number
    validates :citation_number, format: { with: /\AA?\d{8}\Z/i }
    validates :decision_date, :redacted_document_location, :file, presence: true
  end

  def unique_citation_number?
    DecisionDocument.find_by(citation_number: citation_number).nil?
  end

  private

  def unique_citation_number
    return if unique_citation_number?

    errors.add(:citation_number, "already exists")
  end
end
