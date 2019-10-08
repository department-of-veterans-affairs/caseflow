# frozen_string_literal: true

class PrivateBar < Representative
  def queue_tabs
    [
      tracking_tasks_tab
    ]
  end

  def should_write_ihp?(_appeal)
    false
  end
end
