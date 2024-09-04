# frozen_string_literal: true

class CorrespondenceType < ApplicationRecord
  has_many :correspondences
end
