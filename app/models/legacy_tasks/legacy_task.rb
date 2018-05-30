class LegacyTask
  include ActiveModel::Model
  include ActiveModel::Serialization

  ATTRS = [:appeal_id, :assigned_to, :due_on, :assigned_at, :docket_name,
           :docket_date, :added_by, :task_id, :type, :document_id, :assigned_by].freeze

  attr_accessor(*ATTRS)

  ### Serializer Methods Start
  def id
    appeal_id
  end

  def assigned_on
    assigned_at
  end

  delegate :css_id, :name, to: :added_by, prefix: true
  delegate :first_name, :last_name, to: :assigned_by, prefix: true

  def user_id
    assigned_to.css_id
  end

  def task_type
    type
  end
  ### Serializer Methods End

  def self.from_vacols(record, user)
    new(
      due_on: record.date_due,
      docket_name: "legacy",
      added_by: record.added_by,
      docket_date: record.docket_date,
      appeal_id: record.vacols_id,
      assigned_to: user,
      task_id: record.created_at ? record.vacols_id + "-" + record.created_at.strftime("%Y-%m-%d") : nil,
      document_id: record.document_id,
      assigned_by: record.assigned_by
    )
  end

  def self.repository
    @repository ||= QueueRepository
  end
end
