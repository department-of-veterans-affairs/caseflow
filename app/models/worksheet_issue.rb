# frozen_string_literal: true

# Worksheet Issue table represents the worksheet data entered
# by the judge, it is not an official determination on the issue
class WorksheetIssue < CaseflowRecord
  acts_as_paranoid

  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :hearing, foreign_key: :appeal_id, primary_key: :appeal_id

  validates :appeal, :vacols_sequence_id, presence: true

  class << self
    def create_from_issue(appeal, issue)
      WorksheetIssue.find_or_create_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id).tap do |record|
        record.update(notes: issue.note,
                      description: issue.formatted_program_type_levels,
                      disposition: issue.formatted_disposition,
                      from_vacols: true)
      end
    end
  end
end
