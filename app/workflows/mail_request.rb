#frozen_string_literal: true

class MailRequest
  include ActiveModel::Model

  # ask about what should be validated...
  # Could put them in a frozen array.....only having to reference that in future calls

  EXPECTED_PARAMS_FOR_RECIPIENTS_AND_DESTINATIONS = [
                                                    :address_line_1,
                                                    :address_line_2,
                                                    :address_line_3,
                                                    :address_line_4,
                                                    :address_line_5, :address_line_6,
                                                    :city,
                                                    :country_code,
                                                    :postal_code,
                                                    :state,
                                                    :treat_line_2_as_addressee,
                                                    :treat_line_3_as_addressee,
                                                    :country_name, :email_address,
                                                    :phone_number, :recipient_type,
                                                    :name,
                                                    :first_name,
                                                    :middle_name,
                                                    :last_name,
                                                    :participant_id,
                                                    :poa_code,
                                                    :claimant_station_of_jurisdiction
                                                  ]

  def initialize(params)
    @params = params.slice(EXPECTED_PARAMS_FOR_RECIPIENTS_AND_DESTINATIONS)
  end

  def create_a_vbms_distribution
    VbmsDistribution.create(recipient_params_parse)
  end

  def create_a_vbms_distribution_destination
    VbmsDistributionDestination.create(destination_params_parse)
  end

  def destination_params_parse
    {
      address_line_1: @params.address_line_1,
      address_line_2: @params.address_line_2,
      address_line_3: @params.address_line_3,
      address_line_4: @params.address_line_4,
      address_line_5: @params.address_line_5,
      address_line_6: @params.address_line_6,
      city: @params.city,
      country_code: @params.country,
      postal_code: @params.postal_code,
      state: @params.state,
      treat_line_2_as_addressee: @params.treat_line_2_as_addressee,
      treat_line_3_as_addressee: @params.treat_line_3_as_addressee,
      country_name: @params.country_name,
      email_address: @params.email_address,
      phone_number: @params.phone_number
    }
  end

  def recipient_params_parse
    {
      recipient_type: @params,
      name: @params.name,
      first_name: @params.first_name,
      middle_name: @params.middle_name,
      last_name: @params.last_name,
      participant_id: @params.participant_id,
      poa_code: @params.poa_code,
      claimant_station_of_jurisdiction: @params.claimant_station_of_jurisdiction
    }
  end
end
