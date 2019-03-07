# frozen_string_literal: true

class VbmsUploadedDocument < ApplicationRecord
  belongs_to :appeal, optional: false
  validates :document_type, presence: true

  attr_accessor :file
end
