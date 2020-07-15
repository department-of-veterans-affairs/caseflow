# frozen_string_literal: true

class BgsRelatedClaimant < Claimant
  include AssociatedBgsRecord

  bgs_attr_accessor :relationship
end
