# frozen_string_literal: true

module Api
  module V3
    module DecisionReviews
      class BaseContestableIssuesController < BaseController
        SSN_REGEX = /^\d{9}$/.freeze

        before_action :validate_params

        def index
          render json: { data: serialized_contestable_issues }
        end

        private

        def standin_decision_review
          fail Caseflow::Error::MustImplementInSubclass
        end

        def serialized_contestable_issues
          contestable_issues.map do |issue|
            Api::V3::ContestableIssueSerializer.new(issue).serializable_hash[:data]
          end
        end

        def contestable_issues
          # for the time being, rating decisions are not being included.
          # rating decisions are actively being discussed / worked on,
          # and promulgation dates can be unreliable (and therefore require a Claims Assistant's interpretation)
          contestable_issue_generator.contestable_rating_issues +
            contestable_issue_generator.contestable_decision_issues
        end

        def contestable_issue_generator
          @contestable_issue_generator ||= ContestableIssueGenerator.new(standin_decision_review)
        end

        def validate_params
          veteran_valid? && receipt_date_valid?
        end

        def veteran_valid?
          unless veteran_ssn_is_formatted_correctly?
            render_invalid_veteran_ssn
            return false
          end
          unless veteran
            render_veteran_not_found
            return false
          end
          true
        end

        def receipt_date_valid?
          unless receipt_date.is_a? Date
            render_invalid_receipt_date
            return false
          end
          if receipt_date_is_before_the_ama_activation_date
            render_invalid_receipt_date "is before AMA Activation Date (#{ama_activation_date})."
            return false
          end
          if receipt_date_is_in_the_future
            render_invalid_receipt_date "is in the future (today: #{Time.zone.today}; time zone: #{Time.zone})."
            return false
          end
          true
        end

        def veteran
          @veteran ||= VeteranFinder.find_best_match veteran_ssn
        end

        def veteran_ssn
          @veteran_ssn ||= request.headers["X-VA-SSN"].to_s.strip
        end

        def veteran_ssn_is_formatted_correctly?
          !!veteran_ssn.match?(SSN_REGEX)
        end

        def render_invalid_veteran_ssn
          render_errors(
            status: 422,
            code: :invalid_veteran_ssn,
            title: "Invalid Veteran SSN",
            detail: "SSN regex: #{SSN_REGEX.inspect})."
          )
        end

        def render_veteran_not_found
          render_errors(
            status: 404,
            code: :veteran_not_found,
            title: "Veteran Not Found"
          )
        end

        def receipt_date
          @receipt_date ||= begin
                              Date.iso8601 receipt_date_header
                            rescue ArgumentError => error
                              raise unless error.message == "invalid date"

                              nil
                            end
        end

        def receipt_date_header
          request.headers["X-VA-Receipt-Date"]
        end

        def receipt_date_is_before_the_ama_activation_date
          receipt_date <= ama_activation_date
        end

        def ama_activation_date
          Constants::DATES["AMA_ACTIVATION"].to_date
        end

        def receipt_date_is_in_the_future
          receipt_date > Time.zone.today
        end

        def render_invalid_receipt_date(reason = "is not a valid date.")
          render_errors(
            status: 422,
            code: :invalid_receipt_date,
            title: "Invalid Receipt Date",
            detail: "#{receipt_date_header.inspect} #{reason}"
          )
          nil
        end
      end
    end
  end
end
