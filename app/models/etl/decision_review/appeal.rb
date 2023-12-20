# frozen_string_literal: true

class ETL::DecisionReview::Appeal < ETL::DecisionReview
  class << self
    def unique_attributes
      [
        :closest_regional_office,
        :docket_range_date,
        :docket_type,
        :established_at,
        :poa_participant_id,
        :stream_docket_number,
        :stream_type,
        :target_decision_date
      ]
    end

    def merge_original_attributes_to_target(original, target)
      super

      target.benefit_type = original.request_issues.pluck(:benefit_type).uniq.join(",")

      target
    end
  end
end
