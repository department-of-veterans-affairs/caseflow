class Dispatch
  class InvalidClaimError < StandardError; end
  class EndProductAlreadyExistsError < StandardError; end

  def initialize(task:, claim: {}, vacols_note: nil)
    # TODO(jd): If we permanently keep the decision date a non-editable field,
    # we should instead pass that value from the taks.appeal.decision date, rather
    # than use the value passed from the front end
    @claim = Claim.new(claim)
    @task = task
    @vacols_note = vacols_note && vacols_note[0...280]
  end
  attr_accessor :task, :claim, :vacols_note

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

  rescue VBMS::HTTPError => error
    raise parse_vbms_error(error)
  end

  def update_vacols!
    Appeal.repository.update_vacols_after_dispatch!(appeal: task.appeal,
                                                    vacols_note: vacols_note)
  end

  def assign_existing_end_product!(end_product_id:, special_issues:)
    task.transaction do
      task.appeal.update!(special_issues)
      task.assign_existing_end_product!(end_product_id)
      Appeal.repository.update_location_after_dispatch!(appeal: task.appeal)
    end
  end

  private

  def parse_vbms_error(error)
    case error.body
    when /PIF is already in use/
      return EndProductAlreadyExistsError
    when /A duplicate claim for this EP code already exists/
      return EndProductAlreadyExistsError
    else
      return error
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
      unless EndProduct::CODES[end_product_code] == end_product_label
        errors.add(:end_product_label, "must match end_product_code")
      end
    end
  end
end
