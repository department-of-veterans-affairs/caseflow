# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  include HasAppealUpdatedSince

  belongs_to :appeal, polymorphic: true
end
