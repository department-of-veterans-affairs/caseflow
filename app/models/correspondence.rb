# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  has_paper_trail

  has_many :correspondence_documents
  has_many :correspondence_intakes
  has_many :correspondences_appeals
  has_many :appeals, through: :correspondences_appeals
  belongs_to :correspondence_type
  belongs_to :package_document_type
  belongs_to :prior_correspondence, class_name: "Correspondence", optional: true
  belongs_to :veteran
  # has_many :appeals, through: :correspondence_appeals
  has_many :tasks
  # has_many :correspondence_types

  # has_many :correspondence_correspondences
  # has_many :related_correspondences, through: :correspondence_correspondences

  after_create :initialize_correspondence_tasks

  def initialize_correspondence_tasks
    CorrespondenceRootTaskFactory.new(self).create_root_and_sub_tasks!
  end

end
