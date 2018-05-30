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
    vacols_id: :isskey
  }.freeze

  ALLOWED_DISPOSITION_CODES = %w[1 3 4 5 6 8 9].freeze

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
      return if (issue_attrs.keys & [:issprog, :isscode, :isslev1, :isslev2, :isslev3]).empty?

      if issue_attrs.slice(:issprog, :isscode, :isslev1, :isslev2, :isslev3).size != 5
        msg = "All keys must be present: program, issue, level_1, level_2, level_3"
        fail Caseflow::Error::IssueRepositoryError, msg
      end

      if IssueRepository.find_issue_reference(program: issue_attrs[:issprog],
                                              issue: issue_attrs[:isscode],
                                              level_1: issue_attrs[:isslev1],
                                              level_2: issue_attrs[:isslev2],
                                              level_3: issue_attrs[:isslev3]).size != 1
        fail Caseflow::Error::IssueRepositoryError, "Combination of VACOLS Issue codes is invalid: #{issue_attrs}"
      end
    end

    def rename(issue_attrs)
      COLUMN_NAMES.keys.each_with_object({}) do |k, result|
        # skip only if the key is not passed, if the key is passed and the value is nil - include that
        next unless issue_attrs.keys.include? k
        issue_attrs[k] = disposition_to_vacols_format(issue_attrs[k]) if k == :disposition
        result[COLUMN_NAMES[k]] = issue_attrs[k]
        result
      end
    end

    def disposition_to_vacols_format(disposition)
      inverted_dispositions = Constants::VACOLS_DISPOSITIONS_BY_ID.map { |k, v|
        [v.parameterize.underscore.capitalize, k]
      }.to_h
      code = inverted_dispositions[disposition]

      unless ALLOWED_DISPOSITION_CODES.include? code
        fail Caseflow::Error::IssueRepositoryError, "Not allowed disposition: #{disposition}"
      end
      code
    end
  end
end
