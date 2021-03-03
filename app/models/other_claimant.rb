# frozen_string_literal: true

##
# OtherClaimant is used when none of Veteran, Dependent, or Attorney claimant is applicable, largely
# due to not having a canonical BGS source for the claimant's participant ID.
# Currently used for attorney fee cases when the attorney isn't found in the BGS attorney database.

class OtherClaimant < Claimant
  delegate :name, :first_name, :middle_name, :last_name,
           :address, :address_line_1, :address_line_2, :address_line_3,
           :city, :state, :zip, :country,
           :power_of_attorney,
           to: :unrecognized_appellant,
           allow_nil: true

  NIL_ATTRIBUTES = [ # not applicable without CorpDB record
    :date_of_birth,
    :advanced_on_docket?,
    :advanced_on_docket_based_on_age?,
    :advanced_on_docket_motion_granted?
  ].freeze
  NIL_ATTRIBUTES.each do |attribute|
    define_method attribute do |*_args|
      nil
    end
  end

  def relationship
    unrecognized_appellant&.relationship || "Other"
  end

  def save_unrecognized_details!(params, poa_params, poa_participant_id)
    params.permit!
    poa_form = params.delete(:poa_form)
    appellant = create_appellant!(params)
    if poa_form
      if poa_params.present?
        poa_params.permit!
        appellant.update!(unrecognized_power_of_attorney: create_party_detail!(poa_params))
      elsif poa_participant_id.present?
        appellant.update!(poa_participant_id: poa_participant_id)
      end
    end
    appellant
  end

  private

  def create_appellant!(params)
    relationship = params.delete(:relationship)
    UnrecognizedAppellant.create!(
      relationship: relationship,
      claimant_id: id,
      unrecognized_party_detail: create_party_detail!(params)
    )
  end

  def create_party_detail!(params)
    first_name = params.delete(:first_name)
    params[:name] = first_name if params[:party_type] == "individual"
    UnrecognizedPartyDetail.create!(params)
  end
end
