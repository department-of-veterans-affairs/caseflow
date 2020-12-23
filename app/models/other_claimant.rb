# frozen_string_literal: true

##
# OtherClaimant is used when none of Veteran, Dependent, or Attorney claimant is applicable, largely
# due to not having a canonical BGS source for the claimant's participant ID.
# Currently used for attorney fee cases when the attorney isn't found in the BGS attorney database.

class OtherClaimant < Claimant
  validate { |claimant| OtherClaimantValidator.new(claimant).validate }

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
  ]
  NIL_ATTRIBUTES.each do |attribute|
    define_method attribute do
      nil
    end
  end

  def relationship
    unrecognized_appellant&.relationship || "Other"
  end

  def unrecognized_appellant
    @unrecognized_appellant ||= UnrecognizedAppellant.find_by(claimant_id: id)
  end
end
