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

  def save_unrecognized_details!(params)
    params.permit!
    relationship = params.delete(:relationship)
    first_name = params.delete(:first_name)
    params.delete(:poa_form) # Use or save this when intake supports user-supplied POAs
    params[:name] = first_name if params[:party_type] == "individual"
    UnrecognizedAppellant.create!(
      relationship: relationship,
      claimant_id: id,
      unrecognized_party_detail: UnrecognizedPartyDetail.create!(params),
      # Update the next two lines when intake supports user-supplied POAs
      poa_participant_id: nil,
      unrecognized_power_of_attorney: nil
    )
  end
end
