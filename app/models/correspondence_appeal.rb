# frozen_string_literal: true

class CorrespondenceAppeal < ApplicationRecord
  belongs_to :correspondence
  belongs_to :appeal
  has_many :correspondences_appeals_tasks, dependent: :destroy
  has_many :tasks, through: :correspondences_appeals_tasks
end
