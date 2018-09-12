class AdvanceOnDocketGrant < ApplicationRecord
  belongs_to :claimants
  belongs_to :users
end
