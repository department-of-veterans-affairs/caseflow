# frozen_string_literal: true

class Metric < CaseflowRecord
  belongs_to :user

  METRIC_TYPES = %w(error, log, performance)

  validates :type, inclusion: { in: METRIC_TYPES}


end
