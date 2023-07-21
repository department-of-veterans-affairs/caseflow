# frozen_string_literal: true

class VhaBusinessLine < BusinessLine
  def self.singleton
    VhaBusinessLine.first || VhaBusinessLine.create(name: Constants::BENEFIT_TYPES["vha"], url: "vha")
  end

  def included_tabs
    [:incomplete, :in_progress, :completed]
  end

  def tasks_query_type
    {
      incomplete: "on_hold",
      in_progress: "active",
      completed: "recently_completed"
    }
  end
end
