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

  DISPOSITIONS = {
    "1" => "Allowed",
    "3" => "Remanded",
    "4" => "Denied",
    "5" => "Vacated",
    "6" => "Dismissed, Other",
    "8" => "Dismissed, Death",
    "9" => "Withdrawn"
  }

  def self.rename_and_validate_vacols_attrs(issue_attrs)
    issue_attrs = slice_attributes(issue_attrs.symbolize_keys)
    validate_code_combination(issue_attrs)
    issue_attrs
  end

  def self.validate_code_combination(issue_attrs)
    return if (issue_attrs.keys & [:issprog, :isscode, :isslev1, :isslev2, :isslev3]).empty?
    if IssueRepository.find_issue_reference(program: issue_attrs[:issprog],
                                            issue: issue_attrs[:isscode],
                                            level_1: issue_attrs[:isslev1],
                                            level_2: issue_attrs[:isslev2],
                                            level_3: issue_attrs[:isslev3]).size != 1
      fail IssueRepository::IssueError, "Combination of VACOLS Issue codes is invalid: #{issue_attrs}"
    end
  end

  def self.slice_attributes(issue_attrs)
    COLUMN_NAMES.keys.each_with_object({}) do |k, result|
      # skip only if the key is not passed, if the key is passed and the value is nil - include that
      next unless issue_attrs.keys.include? k

      if k == :disposition
        code = DISPOSITIONS.key(issue_attrs[k])
        fail IssueRepository::IssueError, "Not allowed disposition: #{issue_attrs}" unless code
        issue_attrs[k] = code
      end

      result[COLUMN_NAMES[k]] = issue_attrs[k]
      result
    end
  end
end
