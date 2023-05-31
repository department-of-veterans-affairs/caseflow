# frozen_string_literal: true

class MailRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :recipient_type, :name, :first_name, :middle_name, :last_name,
  :participant_id, :poa_code, :claimant_station_of_jurisdiction, :destination_type,
  :address_line_1, :address_line_2, :address_line_3, :address_line_4, :address_line_5,
  :address_line_6, :city, :country_code, :postal_code, :state, :treat_line_2_as_addressee,
  :treat_line_3_as_addressee, :country_name

  with_options presence: true do
    validates :recipient_type, if: :recipient_type_valid?
    validates :first_name, :last_name, if: :person?
    validates :poa_code, :claimant_station_of_jurisdiction, if: :ro_colocated?
    validates :destination_type, if: :destination_type_valid?
    validates :address_line_1, :city, :country_code, if: :physical_mail?
    validates :address_line_2, if: :line_2_addressee?
    validates :address_line_3, if: :line_3_addressee?
    validates :state, :postal_code, if: :us_address?
    validates :country_name, if: :country_name_required?
  end
  validate :name, unless: :person?

  def initialize(recipient_and_destination_hash)
    @recipient_type = recipient_and_destination_hash[:recipient_type]
    @name = recipient_and_destination_hash[:name]
    @first_name = recipient_and_destination_hash[:first_name]
    @middle_name = recipient_and_destination_hash[:middle_name]
    @last_name = recipient_and_destination_hash[:last_name]
    @participant_id = recipient_and_destination_hash[:participant_id]
    @poa_code = recipient_and_destination_hash[:poa_code]
    @claimant_station_of_jurisdiction = recipient_and_destination_hash[:claimant_station_of_jurisdiction]
    @destination_type = recipient_and_destination_hash[:destination_type]
    @address_line_1 = recipient_and_destination_hash[:address_line_1]
    @address_line_2 = recipient_and_destination_hash[:address_line_2]
    @address_line_3 = recipient_and_destination_hash[:address_line_3]
    @address_line_4 = recipient_and_destination_hash[:address_line_4]
    @address_line_5 = recipient_and_destination_hash[:address_line_5]
    @address_line_6 = recipient_and_destination_hash[:address_line_6]
    @city = recipient_and_destination_hash[:city]
    @country_code = recipient_and_destination_hash[:country_code]
    @postal_code = recipient_and_destination_hash[:postal_code]
    @state = recipient_and_destination_hash[:state]
    @treat_line_2_as_addressee = recipient_and_destination_hash[:treat_line_2_as_addressee]
    @treat_line_3_as_addressee = recipient_and_destination_hash[:treat_line_3_as_addressee]
    @country_name = recipient_and_destination_hash[:country_name]
    @vbms_distribution_id = nil
    @comm_package_id = nil
  end

  def call
    if valid?
      distribution = create_a_vbms_distribution
      @vbms_distribution_id = distribution.id
      create_a_vbms_distribution_destination
    else
      raise Caseflow::Error::MissingRecipientInfo
    end
  end

  private

  def create_a_vbms_distribution
    VbmsDistribution.create!(recipient_params_parse)
  end

  def create_a_vbms_distribution_destination
    VbmsDistributionDestination.create!(destination_params_parse)
  end

  def recipient_type_valid?
    unless @recipient_type.blank?
      valid_var = %w[organization person system ro-colocated].include?(@recipient_type)
      valid_var
    end
  end

  def person?
    unless @recipient_type.blank?
      @recipient_type == "person"
    end
  end

  def ro_colocated?
    unless @recipient_type.blank?
      @recipient_type == "ro-colocated"
    end
  end

  def destination_type_valid?
    unless @destination_type.blank?
      %w[domesticAddress internationalAddress militaryAddress derived email sms].include?(
        @destination_type
      )
    end
  end

  def physical_mail?
    unless @destination_type.blank?
      %w[domesticAddress internationalAddress militaryAddress].include?(@destination_type)

    end
  end

  def line_2_addressee?
    unless @treat_line_2_as_addressee.blank?
      @treat_line_2_as_addressee == true
    end
  end

  def line_3_addressee?
    unless @treat_line_3_as_addressee.blank?
      @treat_line_3_as_addressee == true
    end
  end

  def country_name_required?
    unless @destination_type.blank?
      @destination_type == "internationalAddress"
    end
  end

  def us_address?
    unless @destination_type.blank?
      %w[domesticAddress militaryAddress].include?(@destination_type)
    end
  end

  def destination_params_parse
    {
      destination_type: @destination_type,
      address_line_1: @address_line_1,
      address_line_2: @address_line_2,
      address_line_3: @address_line_3,
      address_line_4: @address_line_4,
      address_line_5: @address_line_5,
      address_line_6: @address_line_6,
      city: @city,
      country_code: @country_code,
      postal_code: @postal_code,
      state: @state,
      treat_line_2_as_addressee: @treat_line_2_as_addressee,
      treat_line_3_as_addressee: @treat_line_3_as_addressee,
      country_name: @country_name,
      vbms_distribution_id: @vbms_distribution_id

    }
  end

  def recipient_params_parse
    {
      recipient_type: @recipient_type,
      name: @name,
      first_name: @first_name,
      middle_name: @middle_name,
      last_name: @last_name,
      participant_id: @participant_id,
      poa_code: @poa_code,
      claimant_station_of_jurisdiction: @claimant_station_of_jurisdiction
    }
  end
end
