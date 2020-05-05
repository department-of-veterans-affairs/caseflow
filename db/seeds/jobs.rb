# frozen_string_literal: true

# run jobs that require/create seed data

module Seeds
  class Jobs
    def seed!
      perform_seeding_jobs
    end

    private

    def perform_seeding_jobs
      # Active Jobs which populate tables based on seed data
      UpdateCachedAppealsAttributesJob.perform_now
      NightlySyncsJob.perform_now
    end
  end
end
