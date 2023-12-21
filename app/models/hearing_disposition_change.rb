class HearingDispositionChange < CaseflowRecord
  belongs_to :hearing, polymorphic: true
end
