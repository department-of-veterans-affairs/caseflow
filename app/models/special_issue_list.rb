# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  belongs_to :appeal, polymorphic: true
end
