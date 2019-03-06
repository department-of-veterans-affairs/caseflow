# frozen_string_literal: true

module RoundRobinAssigner
  extend ActiveSupport::Concern

  module ClassMethods
    def next_assignee
      User.find_by_css_id_or_create_with_default_station_id(next_assignee_css_id)
    end

    def latest_task
      where(assigned_to_type: User.name).order("created_at").last
    end

    def last_assignee_css_id
      latest_task ? latest_task.assigned_to.css_id : nil
    end

    def next_assignee_css_id
      fail "list_of_assignees cannot be empty" if list_of_assignees.blank?

      list_of_assignees[next_assignee_index]
    end

    def next_assignee_index
      return 0 unless last_assignee_css_id
      return 0 unless list_of_assignees.index(last_assignee_css_id)

      (list_of_assignees.index(last_assignee_css_id) + 1) % list_of_assignees.length
    end
  end
end
