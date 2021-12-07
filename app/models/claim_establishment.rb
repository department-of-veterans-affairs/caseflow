# frozen_string_literal: true

class ClaimEstablishment < CaseflowRecord
  belongs_to :task, class_name: "Dispatch::Task"

  enum decision_type: {
    full_grant: 1,
    partial_grant: 2,
    remand: 3
  }

  DECSION_TYPES = {
    "Full Grant" => :full_grant,
    "Partial Grant" => :partial_grant,
    "Remand" => :remand
  }.freeze

  # Virtual setter using the appeal information
  def appeal=(appeal)
    self.decision_type = ClaimEstablishment.get_decision_type(appeal)
    self.outcoding_date = appeal.outcoding_date
  end

  # returns the type of a decision based on appeal data
  # If a type is not matched, it returns nil
  def self.get_decision_type(appeal)
    DECSION_TYPES[appeal.dispatch_decision_type]
  end

  def sent_email
    email_recipient && RegionalOfficeEmail.new(recipient: email_recipient, ro_id: email_ro_id)
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: claim_establishments
#
#  id              :integer          not null, primary key
#  decision_type   :integer
#  email_recipient :string
#  ep_code         :string
#  outcoding_date  :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null, indexed
#  email_ro_id     :string
#  task_id         :integer
#
# Foreign Keys
#
#  fk_rails_46071c0164  (task_id => dispatch_tasks.id)
#
