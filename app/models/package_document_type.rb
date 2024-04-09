# frozen_string_literal: true

class PackageDocumentType < ApplicationRecord
  has_many :correspondences

  def self.nod
    find_by(name: Constants.PACKAGE_DOCUMENT_TYPES.NOD)
  end
end
