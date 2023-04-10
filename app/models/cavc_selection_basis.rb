# frozen_string_literal: true

class CavcSelectionBasis < CaseflowRecord
  has_many :cavc_reasons_to_bases
  has_many :cavc_dispositions_to_reasons, through: :cavc_reasons_to_bases
end
