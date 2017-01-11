class Dispatch
  class InvalidClaimError < StandardError; end

  END_PRODUCT_STATUS = {
    "PEND" => "Pending",
    "CLR" => "Cleared",
    "CAN" => "Canceled"
  }.freeze

  END_PRODUCT_CODES = {
    "170APPACT" => "Appeal Action",
    "170APPACTPMC" => "PMC-Appeal Action",
    "170PGAMC" => "AMC-Partial Grant ",
    "170RMD" => "Remand",
    "170RMDAMC" => "AMC-Remand",
    "170RMDPMC" => "PMC-Remand",
    "172GRANT" => "Grant of Benefits",
    "172BVAG" => "BVA Grant",
    "172BVAGPMC" => "PMC-BVA Grant",
    "400CORRC" => "Correspondence",
    "400CORRCPMC" => "PMC-Correspondence",
    "930RC" => "Rating Control",
    "930RCPMC" => "PMC-Rating Control"
  }.freeze

  END_PRODUCT_MODIFIERS = %w(170 172).freeze

  def initialize(claim:, task:)
    # Claim info passed in via browser EP form
    @base_claim = claim.symbolize_keys

    # Full claim with merged in dynamic and default values
    @claim = default_claim_values.merge(dynamic_claim_values).merge(@base_claim)
    @task = task
  end

  def claim_valid?
    valid = true

    # Verify the end product code exists
    valid = false unless @claim[:end_product_code]

    # Verify the end product modifier is valid
    valid = false unless END_PRODUCT_MODIFIERS.include?(@claim[:end_product_modifier])

    # Verify the end product label and code match
    unless END_PRODUCT_CODES[@claim[:end_product_code]] == @claim[:end_product_label]
      valid = false
    end

    valid
  end

  def validate_claim!
    fail InvalidClaimError unless claim_valid?
  end

  # Core method responsible for API call to VBMS to create the end product
  # On success will udpate the task with the end product's claim_id
  def establish_claim!
    validate_claim!
    end_product = Appeal.repository.establish_claim!(claim: @claim,
                                                     appeal: @task.appeal)

    @task.complete!(status: 0, outgoing_reference_id: end_product.claim_id)
  end

  def dynamic_claim_values
    {
      date: Time.now.utc.to_date,

      # TODO(jd): Make this attr dynamic in future PR once
      # we support routing a claim based on special issues
      station_of_jurisdiction: "317"
    }
  end

  def default_claim_values
    {
      benefit_type_code: "1",
      payee_code: "00",
      predischarge: false,
      claim_type: "Claim"
    }
  end

  def filter_dispatch_end_products(end_products)
    end_products.select do |end_product|
      END_PRODUCT_CODES.keys.include? end_product[:claim_type_code]
    end
  end
end
