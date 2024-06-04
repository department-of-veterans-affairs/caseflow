# frozen_string_literal: true

module IgnoreJobExecutionTime
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Include this module in job classes if you anticipate that the job will run
    # several times in a short time span. As a result, the Job execution time
    # does not need to be tracked
    def ignore_job_execution_time?
      true
    end
  end
end
