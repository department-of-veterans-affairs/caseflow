# frozen_string_literal: true

# Creates an AppealAffinity record for an appeal, used to calculate affinity windows during a distribution.
# The default behavior creates a standard Appeal using the appeal factory. An Appeal or VACOLS::Case object
# can be linked by passing it in as the "appeal" parameter.
FactoryBot.define do
  factory :appeal_affinity do
    case_type { appeal.class.name }
    case_id do
      if appeal.is_a?(Appeal)
        appeal.uuid
      elsif appeal.is_a?(VACOLS::Case)
        appeal.bfkey
      end
    end

    docket do
      if appeal.is_a?(Appeal)
        appeal.docket_type
      elsif appeal.is_a?(VACOLS::Case)
        "legacy"
      end
    end

    priority do
      if appeal.is_a?(Appeal)
        (appeal.aod? || appeal.cavc?)
      elsif appeal.is_a?(VACOLS::Case)
        (appeal.bfac == "7" || appeal.notes.map(&:tskactcd).any? { |n| %w[B B1 B2].include?(n) })
      end
    end

    affinity_start_date { Time.zone.now }

    transient do
      # This transient trait can't be called "case" because that is a keyword in Ruby, so we're calling it "Appeal"
      appeal { create(:appeal) }
    end

    after(:create) do |appeal_affinity, evaluator|
      if evaluator.distribution
        appeal_affinity.distribution_id = evaluator.distribution.id
        appeal_affinity.save!
      end

      # This scenario will cover creating affinities from the rails console for local testing
      distributed_case = DistributedCase.find_by(case_id: appeal_affinity.case_id)

      if appeal_affinity.distribution_id.nil? && distributed_case
        appeal_affinity.distribution_id = distributed_case.distribution_id
        appeal_affinity.save!
      end
    end
  end
end
