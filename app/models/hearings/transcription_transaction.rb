# frozen_string_literal: true

class TranscriptionTransaction < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcript
  belongs_to :docket
end
