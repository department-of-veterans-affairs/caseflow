# frozen_string_literal: true

class AppealState < CaseflowRecord
  include HasAppealUpdatedSince
  include AppealStateBelongsToPolymorphicAppealConcern
end
