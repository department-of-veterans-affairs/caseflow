# frozen_string_literal: true

class CavcRemandsAppellantSubstitution < CaseflowRecord
  belongs_to :cavc_remand
  belongs_to :appellant_substitution
end
