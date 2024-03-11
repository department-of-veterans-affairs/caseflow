# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  validates :correspondence_type_id, presence: true
  validates :updated_by_id, presence: true, on: :update
  validates :veteran_id, presence: true

  has_paper_trail
  include PrintsTaskTree
  include AppealableCorrespondence

  has_many :correspondence_documents
  has_many :correspondence_intakes
  has_many :correspondences_appeals
  has_many :appeals, through: :correspondences_appeals
  has_many :correspondence_relations
  has_many :related_correspondences, through: :correspondence_relations, dependent: :destroy
  belongs_to :correspondence_type
  belongs_to :package_document_type
  belongs_to :veteran
  belongs_to :assigned_by, class_name: "User", foreign_key: :assigned_by_id, optional: false

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

  def review_package_task
    Task.find_by(appeal_id: id, appeal_type: type, type: ReviewPackageTask.name)
  end

  def root_task
    Task.find_by(appeal_id: id, appeal_type: type, type: CorrespondenceRootTask.name)
  end

  def nod?
    PackageDocumentType.nod == package_document_type
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
