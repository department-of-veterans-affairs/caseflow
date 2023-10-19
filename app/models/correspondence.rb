# frozen_string_literal: true

class Correspondence < CaseflowRecord
  has_many :correspondence_documents

  # has_many :appeals, through: :correspondence_appeals

  # has_many :tasks

  # has_many :correspondence_types

  # has_many :correspondence_correspondences
  # has_many :related_correspondences, through: :correspondence_correspondences
end
