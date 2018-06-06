module LegacyTaskConcern
  extend ActiveSupport::Concern

  included do
    # task ID is vacols_id concatenated with the date assigned
    validates :task_id, format: { with: /\A[0-9A-Z]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\Z/i }, allow_blank: true
  end

  def vacols_id
    task_id.split("-", 2).first if task_id
  end

  def created_in_vacols_date
    task_id.split("-", 2).second.to_date if task_id
  end
end