# frozen_string_literal: true

class TranscriptionTransaction < CaseflowRecord
  include BelongsToPolymorphicAppealConcerns
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcriptions
  belongs_to :transcript
  belongs_to :docket
end
