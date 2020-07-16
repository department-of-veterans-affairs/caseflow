# frozen_string_literal: true

##
# Dependent claimants are when the veteran's child, spouse, or parent are listed as a decision review's claimant.

class DependentClaimant < BgsRelatedClaimant
  bgs_attr_accessor :relationship
end
