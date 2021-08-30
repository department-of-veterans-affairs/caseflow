# frozen_string_literal: true

# nocov pending additional model behavior
# :nocov:
class VhaProgramOffice < Organization
  def can_receive_task?(_task)
    false
  end
end
# :nocov:
