# frozen_string_literal: true

# Correspondence is a top level object similar to Appeals.
# Serves as a collection of all data related to Correspondence workflow
class Correspondence < CaseflowRecord
  validates :veteran_id, presence: true

  has_paper_trail
  include PrintsTaskTree
  include AppealableCorrespondence

  has_many :correspondence_documents, dependent: :destroy
  has_many :correspondence_appeals, dependent: :destroy
  has_many :appeals, through: :correspondence_appeals
  has_many :correspondence_relations, dependent: :destroy
  has_many :related_correspondences, through: :correspondence_relations, dependent: :destroy
  has_many :correspondence_response_letters, dependent: :destroy
  belongs_to :correspondence_type
  belongs_to :veteran

  after_create :initialize_correspondence_tasks

  # root task manages checks for different child tasks
  delegate :tasks_not_related_to_an_appeal, to: :root_task
  delegate :closed_tasks_not_related_to_an_appeal, to: :root_task
  delegate :correspondence_mail_tasks, to: :root_task
  delegate :open_package_action_task, to: :root_task
  delegate :review_package_task, to: :root_task
  delegate :open_intake_task, to: :root_task

  def initialize_correspondence_tasks
    CorrespondenceRootTaskFactory.new(self).create_root_and_sub_tasks!
  end

  def status
    root_task&.correspondence_status
  end

  def type
    "Correspondence"
  end

  # Alias for cmp_packet_number
  def docket_number
    nil
  end

  # Alias for package_document_type.name
  def docket_name
    nil
  end

  # Cannot use has_many :tasks - Task model does not contain a correspondence_id column
  def tasks
    CorrespondenceTask.where(appeal_id: id, appeal_type: type)
  end

  def root_task
    CorrespondenceRootTask.find_by(appeal_id: id, appeal_type: type)
  end

  def cancel_task_tree_for_appeal_intake
    tasks.where(type: ReviewPackageTask.name).update_all(
      instructions: "An appeal intake was started because this Correspondence is a 10182"
    )
    tasks.update_all(status: Constants.TASK_STATUSES.cancelled)
  end

  # Methods below are included to allow Correspondences to render in explain page
  def veteran_full_name
    veteran.name
  end

  def self.prior_mail(veteran_id, uuid)
    includes([:veteran, :correspondence_type])
      .where(veteran_id: veteran_id).where.not(uuid: uuid)
  end
end
