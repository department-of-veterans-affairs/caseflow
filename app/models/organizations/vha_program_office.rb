# frozen_string_literal: true

class VhaProgramOffice < Organization
  def can_receive_task?(task)
    task.is_a?(VhaDocumentSearchTask)
  end
end
