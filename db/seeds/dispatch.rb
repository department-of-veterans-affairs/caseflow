# frozen_string_literal: true

# create dispatch seeds

module Seeds
  class Dispatch < Base
    def seed!
      setup_dispatch
    end

    private

    def setup_dispatch
      CreateEstablishClaimTasksJob.perform_now
      Timecop.freeze(Date.yesterday) do
        # Tasks prepared on today's date will not be picked up
        ::Dispatch::Task.all.each(&:prepare!)
        # Appeal decisions (decision dates) for partial grants have to be within 3 days
        CSV.foreach(Rails.root.join("docker-bin/oracle_libs", "cases.csv"), headers: true) do |row|
          row_hash = row.to_h
          if %w[amc_full_grants remands_ready_for_claims_establishment].include?(row_hash["vbms_key"])
            VACOLS::Case.where(bfkey: row_hash["vacols_id"]).first.update(bfddec: Time.zone.today)
          end
        end
      end
    rescue AASM::InvalidTransition
      Rails.logger.info("Taks prepare job skipped - tasks were already prepared...")
    end
  end
end
