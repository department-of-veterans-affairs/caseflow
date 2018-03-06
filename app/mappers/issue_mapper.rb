module IssueMapper
  def self.transform_and_validate(issue_hash)
    result = {
      program: issue_hash[:program].try(:[], :code),
      issue: issue_hash[:issue].try(:[], :code),
      level_1: issue_hash[:level_1].try(:[], :code),
      level_2: issue_hash[:level_2].try(:[], :code),
      level_3: issue_hash[:level_3].try(:[], :code),
      note: issue_hash[:note],
      vacols_id: issue_hash[:vacols_id]
    }.select { |k, _v| issue_hash.keys.include? k } # only send updates to key/values that are passed

    validate_issue_codes(result)

    result
  end

  def self.validate_issue_codes(issue_hash)
    if IssueRepository.find_issue_reference(program: issue_hash[:program],
                                            issue: issue_hash[:issue],
                                            level_1: issue_hash[:level_1],
                                            level_2: issue_hash[:level_2],
                                            level_3: issue_hash[:level_3]).size != 1
      fail IssueRepository::IssueError, "Combination of VACOLS Issue codes is invalid: #{issue_hash}"
    end
  end
end
