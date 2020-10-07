# frozen_string_literal: true

# This is for updating the claim label for end products established from Caseflow

class EndProductUpdate < CaseflowRecord
  belongs_to :end_product_establishment
end
