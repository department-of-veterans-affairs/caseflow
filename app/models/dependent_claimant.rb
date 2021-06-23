# frozen_string_literal: true

##
# A DependentClaimant represents a veteran's known relation in CorpDB (child, spouse, or parent)
# who is listed as the claimant on a decision review.

class DependentClaimant < BgsRelatedClaimant
  bgs_attr_accessor :relationship
end
