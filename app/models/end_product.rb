class EndProduct
  include ActiveModel::Model

  STATUSES = {
    "PEND" => "Pending",
    "CLR" => "Cleared",
    "CAN" => "Canceled"
  }.freeze

  INACTIVE_STATUSES = %w(CAN CLR).freeze

  DISPATCH_CODES = {
    "170APPACT" => "Appeal Action",
    "170APPACTPMC" => "PMC-Appeal Action",
    "170PGAMC" => "ARC-Partial Grant",
    "170RMD" => "Remand",
    "170RMDAMC" => "ARC-Remand",
    "170RMDPMC" => "PMC-Remand",
    "172GRANT" => "Grant of Benefits",
    "172BVAG" => "BVA Grant",
    "170RBVAG" => "Remand with BVA Grant",
    "172BVAGPMC" => "PMC-BVA Grant",
    "400CORRC" => "Correspondence",
    "400CORRCPMC" => "PMC-Correspondence",
    "930RC" => "Rating Control",
    "930RCPMC" => "PMC-Rating Control"
  }.freeze

  CODES = DISPATCH_CODES

  FULL_GRANT_MODIFIER = "172".freeze
  DISPATCH_MODIFIERS = %w(170 171 175 176 177 178 179 172).freeze

  attr_accessor :claim_id, :claim_date, :claim_type_code, :modifier, :status_type_code

  def claim_type
    DISPATCH_CODES[claim_type_code] || claim_type_code
  end

  def status_type
    STATUSES[status_type_code] || status_type_code
  end

  # Does this EP have a modifier that might conflict with a new dispatch EP?
  def dispatch_conflict?
    dispatch_modifier? && active?
  end

  # Is this a potential match to be an existing ep for the appeal?
  def potential_match?(appeal)
    dispatch_code? && assignable? && near_decision_date_of?(appeal)
  end

  # TODO: change to more semantic names
  #       this will require JS change, need to wait for redux refactor
  def serializable_hash(_options)
    {
      benefit_claim_id: claim_id,
      claim_receive_date: claim_date.to_formatted_s(:short_date),
      claim_type_code: claim_type,
      end_product_type_code: modifier,
      status_type_code: status_type
    }
  end

  private

  def near_decision_date_of?(appeal)
    (claim_date - appeal.decision_date).abs < 30.days
  end

  # Enforcing rule that there should never be an EP with a 172 modifier that isn't
  # associated with a dispatch code
  def dispatch_code?
    DISPATCH_CODES.keys.include?(claim_type_code) || (modifier == FULL_GRANT_MODIFIER)
  end

  def dispatch_modifier?
    DISPATCH_MODIFIERS.include?(modifier)
  end

  def assignable?
    status_type_code != "CAN"
  end

  def active?
    !INACTIVE_STATUSES.include?(status_type_code)
  end

  class << self
    def from_bgs_hash(hash)
      new(
        claim_id: hash[:benefit_claim_id],
        claim_date: parse_claim_date(hash[:claim_receive_date]),
        claim_type_code: hash[:claim_type_code],
        modifier: hash[:end_product_type_code],
        status_type_code: hash[:status_type_code]
      )
    end

    private

    def parse_claim_date(date)
      Date.strptime(date, "%m/%d/%Y").in_time_zone
    end
  end
end
