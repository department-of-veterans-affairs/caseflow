# frozen_string_literal: true

class IneligibleJudgeList
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    judge_user_id: "Judge User ID",
    judge_name: "Judge Name",
    reason_for_ineligibility: "Reason for Ineligibility"
  }.freeze

  def self.generate_rows(record)

    HEADERS.keys.map { |key| record }
  end

  def self.process
    # Convert results to CSV format
    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      # Iterate through results and add each row to CSV
      ineligible_judges.each do |record|

        csv << generate_rows(record)
      end
    end
  end

  def self.ineligible_judges
    {
      judge_user_id: IneligibleJudgeList.fetch_ineligible_judge_ids,
      judge_name: IneligibleJudgeList.fetch_ineligible_judge_names,
      reason_for_ineligibility: "Reason for Ineligibility TEMPLATE"
    }
  end

  def self.fetch_ineligible_judge_ids
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:id)&.reject(&:blank?) || []
  end

  def self.fetch_ineligible_judge_names
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:css_id)&.reject(&:blank?) || []
  end

  # Reason for Ineligibility - bfcurloc = 96
  # def self.fetch_reason_for_ineligibility
  #   Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:id)&.reject(&:blank?) || [];
  # end
end
