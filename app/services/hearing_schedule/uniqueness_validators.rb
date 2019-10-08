# frozen_string_literal: true

class HearingSchedule::UniquenessValidators
  def initialize(rows)
    @rows = rows
  end

  def duplicate_rows
    @rows.select { |row| @rows.count(row) > 1 }
  end
end
