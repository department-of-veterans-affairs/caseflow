# frozen_string_literal: true

class HearingView < CaseflowRecord
  belongs_to :hearing, polymorphic: true
  belongs_to :user
end
