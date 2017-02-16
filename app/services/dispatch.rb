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
    "170PGAMC" => "AMC-Partial Grant",
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

  def self.filter_dispatch_end_products(end_products)
    end_products.select do |end_product|
      END_PRODUCT_CODES.keys.include? end_product[:claim_type_code]
    end
  end

  def self.map_ep_values(end_products)
    end_products.map do |end_product|
      new_end_product = end_product.clone
      new_end_product[:claim_type_code] = Appeal.map_end_product_value(
        new_end_product[:claim_type_code],
        Dispatch::END_PRODUCT_CODES)
      new_end_product[:status_type_code] = Appeal.map_end_product_value(
        new_end_product[:status_type_code],
        Dispatch::END_PRODUCT_STATUS)
      new_end_product
    end
  end

  def initialize(claim:, task:)
    # TODO(jd): If we permanently keep the decision date a non-editable field,
    # we should instead pass that value from the taks.appeal.decision date, rather
    # than use the value passed from the front end
    @claim = Claim.new(claim)
    @task = task
  end
  attr_accessor :task, :claim

  def validate_claim!
    fail InvalidClaimError unless claim.valid?
  end

  # Core method responsible for API call to VBMS to create the end product
  # On success will udpate the task with the end product's claim_id
  def establish_claim!
    validate_claim!
    end_product = Appeal.repository.establish_claim!(claim: claim.to_hash,
                                                     appeal: task.appeal)

    task.review!(outgoing_reference_id: end_product.claim_id)
  end

  def assign_existing_end_product!(end_product_id:)
    task.transaction do
      task.assign_existing_end_product!(end_product_id)
      Appeal.repository.update_location_after_dispatch!(appeal: task.appeal)
    end
  end

  # Class used for validating the claim object
  class Claim
    include ActiveModel::Validations

    # This is a list of the "variable attrs" that are returned from the
    # browser's End Product form
    PRESENT_VARIABLE_ATTRS =
      %i(date station_of_jurisdiction end_product_modifier end_product_code end_product_label).freeze
    BOOLEAN_VARIABLE_ATTRS =
      %i(gulf_war_registry suppress_acknowledgement_letter).freeze
    VARIABLE_ATTRS = PRESENT_VARIABLE_ATTRS + BOOLEAN_VARIABLE_ATTRS

    attr_accessor(*VARIABLE_ATTRS)

    validates_presence_of(*PRESENT_VARIABLE_ATTRS)
    validates_inclusion_of(*BOOLEAN_VARIABLE_ATTRS, in: [true, false])
    validate :end_product_code_and_label_match

    def initialize(attributes = {})
      attributes.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    # TODO(jd): Consider moving this to date util in the future
    def formatted_date
      Date.strptime(date, "%m/%d/%Y")
    end

    def to_hash
      initial_hash = default_values.merge(dynamic_values)

      result = VARIABLE_ATTRS.each_with_object(initial_hash) do |attr, hash|
        val = instance_variable_get("@#{attr}")
        hash[attr] = val unless val.nil?
      end

      # override date attr, ensuring it's properly formatted
      result[:date] = formatted_date

      result
    end

    def dynamic_values
      {
        # TODO(jd): Make this attr dynamic in future PR once
        # we support routing a claim based on special issues
        # station_of_jurisdiction: "317"
      }
    end

    private

    def default_values
      {
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim"
      }
    end

    def end_product_code_and_label_match
      unless END_PRODUCT_CODES[end_product_code] == end_product_label
        errors.add(:end_product_label, "must match end_product_code")
      end
    end
  end
end
