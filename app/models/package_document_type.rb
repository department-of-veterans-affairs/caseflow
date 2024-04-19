# frozen_string_literal: true

class PackageDocumentType < ApplicationRecord
  has_many :correspondences
end
