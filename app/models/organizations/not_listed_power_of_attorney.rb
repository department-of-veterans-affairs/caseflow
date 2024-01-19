# frozen_string_literal: true

# This is an ephemeral class representing an not listed appellant's power of attorney when there is no listed
# attorney returned from the Corporate DB by that name.

class NotListedPowerOfAttorney < CaseflowRecord
  include ActiveModel::Model

  has_one :unrecognized_appellant
end
