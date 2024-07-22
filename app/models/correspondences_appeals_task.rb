class CorrespondencesAppealsTask < ApplicationRecord
  belongs_to :correspondence, through: :correspondence_appeals
  belongs_to :appeal, through: :correspondence_appeals
  has_many :correspondences, through: :correspondence_appeals
end
