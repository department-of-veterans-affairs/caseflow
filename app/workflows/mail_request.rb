# frozen_string_literal: true

class MailRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  include MailRequestValidator::Distribution
  include MailRequestValidator::DistributionDestination

  attr_reader :vbms_distribution_id, :comm_package_id

  #  Purpose: initializes a mail_request object making use of the passed in hash and also initializing
  #           the attributes of vbms_distribution_id and a comm_package_id. Both set to nil until set
  #           otherwise.
  #
  #  Params: recipient_and_destination_hash - expected parameters that that hold information
  #          that will be used to create a valid VbmsDistribution and valid VbmsDistributionDestination.
  #
  #  Return: nil
  def initialize(recipient_and_destination_hash)
    @recipient_info = recipient_and_destination_hash
    @vbms_distribution_id = nil
    @comm_package_id = nil
  end

  # Purpose: With the passed in parameters, the call method creates both a valid VBMSDistribution and
  #          valid VBMSDistributionDestination. If there is an error it will fail and that information will be provided
  #          to the IDT user.
  #
  def call
    if valid?
      distribution = create_a_vbms_distribution
      @vbms_distribution_id = distribution.id
      create_a_vbms_distribution_destination
    else
      fail Caseflow::Error::MissingRecipientInfo
    end
  end

  private

  def create_a_vbms_distribution
    VbmsDistribution.create!(recipient_params_parse)
  end

  def create_a_vbms_distribution_destination
    VbmsDistributionDestination.create!(destination_params_parse)
  end

  def destination_params_parse
    {
      destination_type: destination_type,
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      address_line_4: address_line_4,
      address_line_5: address_line_5,
      address_line_6: address_line_6,
      city: city,
      country_code: country_code,
      postal_code: postal_code,
      state: state,
      treat_line_2_as_addressee: treat_line_2_as_addressee,
      treat_line_3_as_addressee: treat_line_3_as_addressee,
      country_name: country_name,
      vbms_distribution_id: vbms_distribution_id
    }
  end

  def recipient_params_parse
    {
      recipient_type: recipient_type,
      name: name,
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      participant_id: participant_id,
      poa_code: poa_code,
      claimant_station_of_jurisdiction: claimant_station_of_jurisdiction,
      created_by_id: RequestStore[:current_user].id
    }
  end

  def recipient_type
    @recipient_info[:recipient_type]
  end

  def name
    @recipient_info[:name]
  end

  def first_name
    @recipient_info[:first_name]
  end

  def middle_name
    @recipient_info[:middle_name]
  end

  def last_name
    @recipient_info[:last_name]
  end

  def participant_id
    @recipient_info[:participant_id]
  end

  def poa_code
    @recipient_info[:poa_code]
  end

  def claimant_station_of_jurisdiction
    @recipient_info[:claimant_station_of_jurisdiction]
  end

  def destination_type
    @recipient_info[:destination_type]
  end

  # :reek:UncommunicativeMethodName
  def address_line_1
    @recipient_info[:address_line_1]
  end

  # :reek:UncommunicativeMethodName
  def address_line_2
    @recipient_info[:address_line_2]
  end

  # :reek:UncommunicativeMethodName
  def address_line_3
    @recipient_info[:address_line_3]
  end

  # :reek:UncommunicativeMethodName
  def address_line_4
    @recipient_info[:address_line_4]
  end

  # :reek:UncommunicativeMethodName
  def address_line_5
    @recipient_info[:address_line_5]
  end

  # :reek:UncommunicativeMethodName
  def address_line_6
    @recipient_info[:address_line_6]
  end

  def city
    @recipient_info[:city]
  end

  def country_code
    @recipient_info[:country_code]
  end

  def postal_code
    @recipient_info[:postal_code]
  end

  def state
    @recipient_info[:state]
  end

  def treat_line_2_as_addressee
    @recipient_info[:treat_line_2_as_addressee]
  end

  def treat_line_3_as_addressee
    @recipient_info[:treat_line_3_as_addressee]
  end

  def country_name
    @recipient_info[:country_name]
  end
end
