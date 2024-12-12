# frozen_string_literal: true

class VbmsDocumentType < ApplicationRecord
  has_many :correspondence_documents
end
