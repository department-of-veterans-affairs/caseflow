# frozen_string_literal: true

##
# Tracks when an end product established in Caseflow has its end product code manually changed outside of Caseflow.

class EndProductCodeUpdate < CaseflowRecord
  belongs_to :end_product_establishment
end
