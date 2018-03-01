class Fakes::IssueRepository
  class << self
    def create_vacols_issue(_css_id, _issue_hash)
      OpenStruct.new
    end
  end
end
