# frozen_string_literal: true

class RampIssue < CaseflowRecord
  belongs_to :review, polymorphic: true
  belongs_to :source_issue, class_name: "RampIssue"

  def source_issue_id=(source_issue_id)
    super(source_issue_id)
    self.description ||= source_issue.description
  end

  def contention=(contention)
    self.contention_reference_id = contention.id
    self.description = contention.text
  end

  def contention_text
    Contention.new(description).text
  end

  def serialize
    Intake::RampIssueSerializer.new(self).serializable_hash[:data][:attributes]
  end
end
