# frozen_string_literal: true

module Api
  module V3
    module DecisionReviews
      module Appeals
        class ContestableIssuesController < BaseContestableIssuesController
          private

          def standin_decision_review
            @standin_decision_review ||= Appeal.new(
              veteran_file_number: veteran.file_number,
              receipt_date: receipt_date
            )
          end
        end
      end
    end
  end
end
