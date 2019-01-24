class AsyncableJobs
  attr_accessor :jobs

  def initialize(page: 1)
    @page = page
    @jobs = gather_jobs
  end

  def models
    @models ||= ActiveRecord::Base.descendants
      .select { |c| c.included_modules.include?(Asyncable) }
      .reject(&:abstract_class?)
  end

  private

  # TODO: how to support paging when coallescing so many different models?
  def gather_jobs
    expired_jobs = []
    models.each do |klass|
      expired_jobs << klass.potentially_stuck
    end
    expired_jobs.flatten.sort_by(&:sort_by_submitted_at)
  end
end
