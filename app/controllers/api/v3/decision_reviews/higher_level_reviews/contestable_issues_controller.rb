# frozen_string_literal: true

module Api
  module V3
    module DecisionReviews
      module HigherLevelReviews
        class ContestableIssuesController < BaseContestableIssuesController
          include ApiV3FeatureToggleConcern

          before_action only: [:index] do
            api_released?(:api_v3_higher_level_reviews_contestable_issues)
          end

          private

          def standin_decision_review
            @standin_decision_review ||= HigherLevelReview.new(
              veteran_file_number: veteran.file_number,
              receipt_date: receipt_date,
              # must be in ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE for can_contest_rating_issues?
              benefit_type: benefit_type
            )
          end

          def validate_params
            super && benefit_type_valid?
          end

          def benefit_type_valid?
            unless benefit_type.in? benefit_types
              render_invalid_benefit_type
              return false
            end
            true
          end

          def benefit_type
            @benefit_type ||= params[:benefit_type]
          end

          def benefit_types
            Constants::BENEFIT_TYPES.keys
          end

          def render_invalid_benefit_type
            render_errors(
              status: 422,
              code: :invalid_benefit_type,
              title: "Invalid Benefit Type",
              detail: "Benefit type #{benefit_type.inspect} is invalid. Must be one of: #{benefit_types.inspect}"
            )
          end
        end
      end
    end
  end
end
