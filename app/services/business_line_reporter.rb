# frozen_string_literal: true

require "csv"

class BusinessLineReporter
  attr_reader :task

  def initialize(task:, verbose: false)
    @task = task
    @verbose = verbose
  end

  def as_csv
    CSV.generate do |csv|
      csv << %w[type id claimant_name created tasks_url veteran_participant_id business_line, issue_count]
      task.each do |tasks|
        csv << [
          tasks[:type],
          tasks[:id],
          tasks.dig(:claimant, :name),
          tasks[:created_at].strftime("%Y-%m-%d"),
          tasks[:tasks_url],
          tasks[:veteran_participant_id],
          tasks[:business_line],
          tasks.dig(:appeal, :issueCount)
        ].flatten
      end
    end
  end
end