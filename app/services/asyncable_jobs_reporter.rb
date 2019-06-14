# frozen_string_literal: true

require "csv"

class AsyncableJobsReporter
  attr_reader :jobs

  def initialize(jobs:)
    @jobs = jobs
  end

  def as_csv
    CSV.generate do |csv|
      csv << %w[type id submitted last_submitted attempted_at error participant_id]
      jobs.each do |job|
        klass = job.class
        csv << [
          klass.to_s,
          job.id,
          job[klass.submitted_at_column],
          job[klass.last_submitted_at_column],
          job[klass.attempted_at_column],
          sanitize_error(job),
          job.try(:veteran).try(:participant_id)
        ]
      end
    end
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

  def sanitize_error(job)
    # keep PII out of output
    (job[job.class.error_column] || "none").gsub(/\s.+/s, "")
  end

  def build_summary
    report = {}
    jobs.each do |job|
      cls = job.class.to_s
      age = ((Time.zone.now - job.sort_by_last_submitted_at) / 3600 / 24).ceil.to_s
      err = sanitize_error(job)
      report[cls] ||= {}
      report[cls][age] ||= { err => 0 }
      report[cls][age][err] ||= 0
      report[cls][age][err] += 1
    end
    report
  end
end
