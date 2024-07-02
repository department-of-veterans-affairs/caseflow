# frozen_string_literal: true

class Notification < CaseflowRecord
  belongs_to :notifiable, polymorphic: true

  alias appeal notifiable

  self.ignored_columns = ["notification_events_id"]
end
