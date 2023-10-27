# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  has_many :correspondence_documents
  belongs_to :prior_correspondence, class_name: "Correspondence", optional: true

  # has_many :appeals, through: :correspondence_appeals
  # has_many :tasks
  # has_many :correspondence_types

  # has_many :correspondence_correspondences
  # has_many :related_correspondences, through: :correspondence_correspondences
end
