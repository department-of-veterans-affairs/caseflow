module IssueMapper
  COLUMN_NAMES = {
    program: :issprog,
    issue: :isscode,
    level_1: :isslev1,
    level_2: :isslev2,
    level_3: :isslev3,
    note: :issdesc,
    vacols_id: :isskey
  }.freeze

  def self.rename_and_validate_vacols_attrs(issue_attrs)
    issue_attrs = slice_attributes(issue_attrs.deep_symbolize_keys)
    if IssueRepository.find_issue_reference(program: issue_attrs[:issprog],
                                            issue: issue_attrs[:isscode],
                                            level_1: issue_attrs[:isslev1],
                                            level_2: issue_attrs[:isslev2],
                                            level_3: issue_attrs[:isslev3]).size != 1
      fail IssueRepository::IssueError, "Combination of VACOLS Issue codes is invalid: #{issue_attrs}"
    end
    issue_attrs
  end

  def self.slice_attributes(issue_attrs)
    [:program, :issue, :level_1, :level_2, :level_3, :note, :vacols_id].each_with_object({}) do |k, result|
      next unless issue_attrs[k]
      result[COLUMN_NAMES[k]] = issue_attrs[k].is_a?(Hash) ? issue_attrs[k].try(:[], :code) : issue_attrs[k]
      result
    end
  end
end
