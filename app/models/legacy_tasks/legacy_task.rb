class LegacyTask
  include ActiveModel::Model
  include ActiveModel::Serialization

  ATTRS = [:id, :appeal_id, :assigned_to, :assigned_at, :docket_name, :previous_task,
           :docket_date, :added_by, :task_id, :action, :document_id, :assigned_by, :work_product].freeze

  attr_accessor(*ATTRS)
  attr_writer :appeal

  TASK_ID_REGEX = /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i.freeze

  def available_actions_unwrapper(user, role)
    available_actions(user, role).map { |action| build_action_hash(action, user) }
  end

  def build_action_hash(action, user)
    { label: action[:label], value: action[:value], data: action[:func] ? send(action[:func], user) : nil }
  end

  def add_admin_action_data(_user)
    {
      redirect_after: "/queue",
      selected: nil,
      options: Constants::CO_LOCATED_ADMIN_ACTIONS.map do |key, value|
        {
          label: value,
          value: key
        }
      end,
      type: ColocatedTask.name
    }
  end

  def assign_to_attorney_data(_user)
    {
      selected: nil,
      options: nil,
      type: AttorneyLegacyTask.name
    }
  end

  ### Serializer Methods Start
  def assigned_on
    assigned_at
  end

  def label
    action
  end

  def hide_from_case_timeline
    false
  end

  def hide_from_task_snapshot
    false
  end

  def serializer_class
    ::WorkQueue::LegacyTaskSerializer
  end

  delegate :css_id, :name, to: :added_by, prefix: true
  delegate :first_name, :last_name, :pg_id, :css_id, to: :assigned_by, prefix: true

  def user_id
    assigned_to&.css_id
  end

  def assigned_to_pg_id
    assigned_to&.id
  end

  def appeal
    @appeal ||= LegacyAppeal.find(appeal_id)
  end

  def appeal_type
    appeal.class.name
  end

  def days_waiting
    (Time.zone.today - assigned_at.to_date).to_i if assigned_at
  end

  def available_actions(_role)
    []
  end

  ### Serializer Methods End

  def self.from_vacols(record, appeal, user)
    new(
      id: record.vacols_id,
      docket_name: "legacy",
      added_by: record.added_by,
      docket_date: record.docket_date.try(:to_date),
      appeal_id: appeal.id,
      assigned_to: user,
      assigned_at: record.assigned_to_location_date.try(:to_date),
      task_id: record.created_at ? record.vacols_id + "-" + record.created_at.strftime("%Y-%m-%d") : nil,
      document_id: record.document_id,
      assigned_by: record.assigned_by,
      appeal: appeal
    )
  end

  def self.repository
    @repository ||= QueueRepository
  end
end
