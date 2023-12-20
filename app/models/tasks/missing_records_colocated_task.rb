# frozen_string_literal: true

class MissingRecordsColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.missing_records
  end
end
