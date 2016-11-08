class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  TASKS_BY_URL = {
    "/dispatch/establishclaim": [:EstablishClaim]
  }.freeze

  class << self
    def unassigned
      where(user_id: nil)
    end

    def newest_first
      order(created_at: :desc)
    end

    def find_by_url(url)
      task_types = TASKS_BY_URL[url]
      where(type: task_types)
    end
  end

  def start_text
    type.titlecase
  end
end
