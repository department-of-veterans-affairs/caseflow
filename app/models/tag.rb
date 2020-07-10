# frozen_string_literal: true

class Tag < CaseflowRecord
  has_many :documents_tags
  has_many :documents, through: :documents_tags

  validates :text, presence: true
end
