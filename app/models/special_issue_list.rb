# frozen_string_literal: true

class SpecialIssueList < CaseflowRecord
  include HasAppealUpdatedSince

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
end
