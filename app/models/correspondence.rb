# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  include PrintsTaskTree

  has_many :correspondence_documents
  has_many :correspondence_intakes
  has_many :correspondences_appeals
  has_many :appeals, through: :correspondences_appeals
  has_many :correspondence_relations
  has_many :related_correspondences, through: :correspondence_relations, dependent: :destroy
  belongs_to :correspondence_type
  belongs_to :package_document_type
  belongs_to :veteran

  after_create :initialize_correspondence_tasks

  def initialize_correspondence_tasks
    CorrespondenceRootTaskFactory.new(self).create_root_and_sub_tasks!
  end

  def type
    "Correspondence"
  end

  # Cannot use has_many :tasks - Task model does not contain a correspondence_id column
  def tasks
    Task.where(appeal_id: id, appeal_type: type)
  end

  # Methods below are included to allow Correspondences to render in explain page

  # Alias for cmp_packet_number
  def docket_number
    cmp_packet_number
  end

  # Alias for package_document_type.name
  def docket_name
    package_document_type.name
  end
end
