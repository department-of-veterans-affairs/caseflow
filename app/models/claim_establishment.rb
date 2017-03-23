class ClaimEstablishment < ActiveRecord::Base
  belongs_to :task

  enum decision_type: {
    partial_grant: 0,
    full_grant: 1,
    remand: 2
  }

  DECSION_TYPES = {
    "Full Grant" => :full_grant,
    "Partial Grant" => :partial_grant,
    "Remand" => :remand
  }.freeze

  # virtual setter using the appeal information
  def appeal=(appeal)
    self.decision_type = ClaimEstablishment.get_decision_type(appeal)
  end

  # returns the type of a decision based on appeal data
  # If a type is not matched, it returns nil
  def self.get_decision_type(appeal)
    DECSION_TYPES[appeal.decision_type]
  end
end
