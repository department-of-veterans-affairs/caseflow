# Worksheet Issue table represents the worksheet data entered
# by the judge, it is not an official determination on the issue
class WorksheetIssue < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :hearing, foreign_key: :appeal_id, primary_key: :appeal_id

  class << self
    def create_from_issue(appeal, issue)
      WorksheetIssue.find_or_create_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id).tap do |record|
        record.update(program: issue.program,
                      name: issue.type[:name],
                      levels: issue.levels,
                      description: issue.description,
                      from_vacols: true)
      end
    end
  end
end
