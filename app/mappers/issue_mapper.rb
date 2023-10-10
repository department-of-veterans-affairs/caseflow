# frozen_string_literal: true

module IssueMapper
  COLUMN_NAMES = {
    program: :issprog,
    issue: :isscode,
    level_1: :isslev1,
    level_2: :isslev2,
    level_3: :isslev3,
    note: :issdesc,
    disposition: :issdc,
    disposition_date: :issdcls,
    vacols_id: :isskey,
    mst_status: :issmst,
    pact_status: :isspact
  }.freeze

  # For disposition descriptions, please see the VACOLS_DISPOSITIONS_BY_ID file
  ALLOWED_DISPOSITION_CODES = %w[1 3 4 5 6 8 O P G S X L].freeze

  class << self
    def rename_and_validate_vacols_attrs(action:, issue_attrs:)
      slogid = issue_attrs[:vacols_user_id]
      issue_attrs = rename(issue_attrs.symbolize_keys)

      return {} if issue_attrs.blank?

      validate!(issue_attrs)

      case action
      when :create
        issue_attrs[:issaduser] = slogid
        issue_attrs[:issadtime] = VacolsHelper.local_time_with_utc_timezone
      when :update
        issue_attrs[:issmduser] = slogid
        issue_attrs[:issmdtime] = VacolsHelper.local_time_with_utc_timezone
      end
      issue_attrs
    end

    private

    def validate!(issue_attrs)
      return if (issue_attrs.keys & [:issprog, :isscode, :isslev1, :isslev2, :isslev3, :issmst, :isspact]).empty?

      if issue_attrs.slice(:issprog, :isscode, :isslev1, :isslev2, :isslev3, :issmst, :isspact).size != 7
        msg = "All keys must be present: program, issue, level_1, level_2, level_3, mst_status, pact_status"
        fail Caseflow::Error::IssueRepositoryError, message: msg
      end

      if IssueRepository.find_issue_reference(program: issue_attrs[:issprog],
                                              issue: issue_attrs[:isscode],
                                              level_1: issue_attrs[:isslev1],
                                              level_2: issue_attrs[:isslev2],
                                              level_3: issue_attrs[:isslev3]).size != 1
        msg = "Combination of VACOLS Issue codes is invalid: #{issue_attrs}"
        fail Caseflow::Error::IssueRepositoryError, message: msg
      end
    end

    def rename(issue_attrs)
      COLUMN_NAMES.keys.each_with_object({}) do |k, result|
        # skip only if the key is not passed, if the key is passed and the value is nil - include that
        next unless issue_attrs.key?(k)

        issue_attrs[k] = disposition_to_vacols_format(issue_attrs[k]) if k == :disposition
        issue_attrs[k] = issue_attrs[k][0..99] if k == :note && issue_attrs[k]
        result[COLUMN_NAMES[k]] = issue_attrs[k]
        result
      end
    end

    def disposition_to_vacols_format(disposition)
      # allow nil for rolling back issues
      return if disposition.nil?

      unless ALLOWED_DISPOSITION_CODES.include? disposition
        readable_disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[disposition]
        msg = "Not allowed disposition: #{readable_disposition} (#{disposition})"
        fail Caseflow::Error::IssueRepositoryError, message: msg
      end
      disposition
    end
  end
end
