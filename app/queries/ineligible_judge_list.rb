# frozen_string_literal: true

class IneligibleJudgeList
  # define CSV headers and use this to pull fields to maintain order
  HEADERS = {
    caseflow_user_id: "Caseflow User ID",
    satty_id: "satty ID",
    judge_name: "Judge Name",
    judge_css_id: "CSS ID",
    judge_sdomain_id: "Judge SDomain ID",
    reason_for_ineligibility: "Reason for Ineligibility"
  }.freeze

  EMPTY_KEY_VALUE = "No Key Present"
  INACTIVE_VACOLS = CaseDistributionIneligibleJudges.ineligible_vacols_judges
  INACTIVE_CASEFLOW = CaseDistributionIneligibleJudges.ineligible_caseflow_judges

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
    css_id_value = record.key?(:css_id) ? record[:css_id] : EMPTY_KEY_VALUE
    sdomainid_value = record.key?(:sdomainid) ? record[:sdomainid] : EMPTY_KEY_VALUE

    {
      caseflow_user_id: record.key?(:id) ? record[:id] : nil,
      satty_id: record.key?(:sattyid) ? record[:sattyid] : nil,
      judge_name: get_judge_name(css_id_value, record[:sattyid]),
      judge_css_id: css_id_value,
      judge_sdomain_id: sdomainid_value,
      reason_for_ineligibility: get_reason_for_ineligibility(css_id_value, sdomainid_value)
    }
  end

  def self.get_reason_for_ineligibility(css_id_value, sdomainid_value)
    inactive_caseflow_user = INACTIVE_CASEFLOW.find { |caseflow_user| caseflow_user[:css_id] == css_id_value }
    inactive_vacols_user = INACTIVE_VACOLS.find { |vacols_user| vacols_user[:sdomainid] == sdomainid_value }

    @reason = if inactive_caseflow_user && inactive_vacols_user
                "BOTH"
              elsif inactive_caseflow_user
                "CASEFLOW"
              elsif inactive_vacols_user
                "VACOLS"
              end
  end

  def self.get_judge_name(css_id_value, sattyid_value)
    @judge_name = if css_id_value != EMPTY_KEY_VALUE && !css_id_value.nil?
                    User.find_by(css_id: css_id_value).full_name
                  elsif sattyid_value != EMPTY_KEY_VALUE && !sattyid_value.nil?
                    VACOLS::Staff.find_by(sattyid: sattyid_value).snamef
                  end
  end
end
