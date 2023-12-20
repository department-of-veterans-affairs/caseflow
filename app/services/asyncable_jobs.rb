# frozen_string_literal: true

class AsyncableJobs
  attr_accessor :jobs
  attr_reader :page, :page_size, :total_jobs, :total_pages, :veteran_file_number

  def self.models
    ActiveRecord::Base.descendants
      .select { |c| c.included_modules.include?(Asyncable) }
      .reject(&:abstract_class?)
  end

  def initialize(page: 1, page_size: 50, veteran_file_number: nil)
    @page = page
    @page_size = page_size
    @veteran_file_number = veteran_file_number
    @jobs = gather_jobs
  end

  def find_by_error(msg)
    msg_regex = msg.is_a?(Regexp) ? msg : /#{msg}/
    jobs.select { |j| msg_regex.match?(j[j.class.error_column]) }
  end

  private

  def gather_jobs
    expired_jobs = []
    self.class.models.each do |klass|
      expired_jobs << klass.potentially_stuck
    end
    jobs = expired_jobs.flatten.sort_by(&:sort_by_last_submitted_at)

    if veteran_file_number.present?
      jobs = jobs.select { |job| job.try(:veteran).try(:file_number) == veteran_file_number }
    end

    return paginated_jobs(jobs) if page_size > 0

    jobs
  end

  def paginated_jobs(jobs)
    @total_jobs = jobs.length
    @total_pages = (total_jobs / page_size).to_i
    @total_pages += 1 if total_jobs % page_size
    jobs.slice(page_start, page_size)
  end

  def page_start
    return 0 if page < 2

    (page - 1) * page_size
  end
end
