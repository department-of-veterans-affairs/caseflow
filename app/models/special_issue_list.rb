# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  include HasAppealUpdatedSince

  include SpecialIssueListBelongsToPolymorphicAppealConcern
end
