# frozen_string_literal: true

class IneligibleJudgeList
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    judge_user_id: "Judge User ID",
    judge_name: "Judge Name",
    judge_css_id: "CSS ID",
    judge_sdomain_id: "Judge SDomain ID",
    reason_for_ineligibility: "Reason for Ineligibility"
  }.freeze

  def self.generate_rows(record)
    HEADERS.keys.map { |key| record[key] }
  end

  def self.process
    # Convert results to CSV format
    CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << HEADERS.values

      ineligible_judges = Rails.cache.fetch("case_distribution_ineligible_judges")
      # Iterate through results and add each row to CSV
      ineligible_judges.each do |record|
        csv << generate_rows(parse_record(record))
      end
    end
  end

  def self.parse_record(record)
    css_id_value = record.key?(:css_id) ? record[:css_id] : "No Key Present"
    sdomainid_value = record.key?(:sdomainid) ? record[:sdomainid] : "No Key Present"

    {
      judge_user_id: record[:id],
      judge_name: "Test Name",
      judge_css_id: css_id_value,
      judge_sdomain_id: sdomainid_value,
      reason_for_ineligibility: get_reason_for_ineligibility(css_id_value, sdomainid_value)
    }
  end

  # if CSS_ID key is NOT present and SDomainID key IS present, it originates from VACOLS
  # if CSS_ID and SDomainID keys are BOTH present, the ineligibility originates form BOTH
  # if CSS_ID key is present without SDomainID key then it originates from caseflow
  def self.get_reason_for_ineligibility(css_id_value, sdomainid_value)
    reason = ""
    if css_id_value == "No Key Present"
      if sdomainid_value != "No Key Present"
        reason = "VACOLS"
      end
    end
    if css_id_value != "No Key Present"
      if sdomainid_value != "No Key Present"
        reason = "BOTH"
      end
      reason = "CASEFLOW"
    end
    reason
  end
end
