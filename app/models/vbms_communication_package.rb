# frozen_string_literal: true

class VbmsCommunicationPackage < ApplicationRecord
  has_one :vbms_uploaded_document
  belongs_to :vbms_distribution
end
