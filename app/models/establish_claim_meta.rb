class EstablishClaimMeta < ActiveRecord::Base
  self.table_name = "establish_claims"
  belongs_to :task

  enum decision_type: {
    partial_grant: 0,
    full_grant: 1,
    remand: 2
  }

end