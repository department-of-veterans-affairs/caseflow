# frozen_string_literal: true

module Api::V3::Concerns::Validation
  extend ActiveSupport::Concern
  include Api::V3::Concerns::Helpers

  DEFAULT_ERROR = Api::V3::MalformedRequestError

  private

  def benefit_type?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.in? Api::V3::HigherLevelReviewPreintake::BENEFIT_TYPES

    fail exception, join_present(name_of_value, "is not a benefit type (line of business): <#{value}>") if exception

    false
  end

  def nullable_benefit_type?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.nil? || benefit_type?(value, exception: nil)

    if exception
      fail exception, join_present(
        name_of_value,
        "is neither a benefit type (line of business) nor nil: <#{value}>"
      )
    end

    false
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def nonrating_issue_category_for_benefit_type?(
    category,
    benefit_type,
    names_of_values: %w[category benefit_type],
    exception: DEFAULT_ERROR
  )
    return false unless benefit_type?(
      benefit_type,
      name_of_value: names_of_values.is_a?(Array) && names_of_values[1],
      exception: exception
    )

    categories = Api::V3::HigherLevelReviewPreintake::NONRATING_ISSUE_CATEGORIES[benefit_type]
    return true if category.in? categories

    names_of_values = if names_of_values.is_a?(Array) && names_of_values.length == 2
                        "for #{names_of_values[0]} and #{names_of_values[1]},"
                      end

    if exception
      fail exception, join_present(
        names_of_values,
        "either <#{category}> is not a valid category for benefit type <#{benefit_type}>,",
        "or <#{benefit_type}> isn't a valid benefit type."
      )
    end

    false
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def nullable_nonrating_issue_category_for_benefit_type?(
    category,
    benefit_type,
    names_of_values: %w[category benefit_type],
    exception: DEFAULT_ERROR
  )
    return true if category.nil? ||
                   nonrating_issue_category_for_benefit_type?(category, benefit_type, exception: nil)

    names_of_values = if names_of_values.is_a?(Array) && names_of_values.length == 2
                        "for #{names_of_values[0]} and #{names_of_values[1]},"
                      end

    name_of_category_variable = if names_of_values.is_a?(Array) && names_of_values[0].present?
                                  names_of_values[0]
                                else
                                  "category specified"
                                end

    if exception
      fail exception, join_present(
        names_of_values,
        "either #{name_of_category_variable} isn't nil,",
        "or <#{category}> isn't a valid category for benefit type <#{benefit_type}>,",
        "or <#{benefit_type}> isn't a valid benefit type."
      )
    end

    false
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def payee_code?(value, name_of_value: nil, exception: DEFAULT_ERROR)
    return true if value.in? Api::V3::RequestIssuePreintake::PAYEE_CODES

    fail exception, join_present(name_of_value, "is not a valid payee code: <#{value}>") if exception

    false
  end
end
