# frozen_string_literal: true

class AsyncableJobsReporter
  attr_accessor :jobs

  def initialize(jobs:)
    self.jobs = jobs
  end

  # summarize all jobs by class and error and age
  def summary
    @summary ||= build_summary
  end

  def summarize
    output = []
    summary.keys.sort.each do |cls|
      total = 0
      summary[cls].keys.sort.each do |age|
        summary[cls][age].keys.sort.each do |err|
          count = summary[cls][age][err]
          total += count
          output << "#{cls} has #{count} jobs #{age} days old with error #{err}"
        end
      end
      output << "#{cls} has #{total} total jobs in queue"
    end
    output.join("\n")
  end

  private

  def build_summary
    report = {}
    jobs.each do |job|
      cls = job.class.to_s
      age = ((Time.zone.now - job.sort_by_last_submitted_at) / 3600 / 24).ceil.to_s
      # keep PII out of output
      err = (job[job.class.error_column] || "none").gsub(/\s.+/s, "")
      report[cls] ||= {}
      report[cls][age] ||= { err => 0 }
      report[cls][age][err] ||= 0
      report[cls][age][err] += 1
    end
    report
  end
end
