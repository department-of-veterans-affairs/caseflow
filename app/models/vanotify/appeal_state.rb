# frozen_string_literal: true

class AppealState < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal(:appeal)
end
