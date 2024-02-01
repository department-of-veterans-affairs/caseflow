# frozen_string_literal: true

class PackageDocumentType < ApplicationRecord
  NOD_NAME = "10182"

  has_many :correspondences

  def self.nod
    find_by(name: NOD_NAME)
  end
end
