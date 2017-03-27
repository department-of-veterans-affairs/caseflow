class ClaimEstablishment < ActiveRecord::Base
  belongs_to :task

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
    DECSION_TYPES[appeal.decision_type]
  end

  def ep_description
    ep_label && "#{ep_code} - #{ep_label}"
  end

  def sent_email
    email_recipient && RegionalOfficeEmail.new(recipient: email_recipient, ro_id: email_ro_id)
  end

  private

  def ep_label
    @ep_label ||= Dispatch::END_PRODUCT_CODES[ep_code]
  end
end
