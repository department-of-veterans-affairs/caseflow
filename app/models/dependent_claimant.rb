# frozen_string_literal: true

##
# A DependentClaimant represents a veteran's known relation in CorpDB (child, spouse, or parent)
# who is listed as the claimant on a decision review.

class DependentClaimant < BgsRelatedClaimant
  bgs_attr_accessor :relationship
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: claimants
#
#  id                   :bigint           not null, primary key
#  decision_review_type :string           not null, indexed => [decision_review_id]
#  notes                :text
#  payee_code           :string
#  type                 :string           default("Claimant")
#  created_at           :datetime
#  updated_at           :datetime         indexed
#  decision_review_id   :bigint           not null, indexed => [decision_review_type]
#  participant_id       :string           not null, indexed
#
