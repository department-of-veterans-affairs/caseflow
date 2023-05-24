# frozen_string_literal: true

class MailRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :recipient_type, :name, :first_name, :middle_name, :last_name,
  :participant_id, :poa_code, :claimant_station_of_jurisdiction, :destination_type,
  :address_line_1, :address_line_2, :address_line_3, :address_line_4, :address_line_5,
  :address_line_6, :city, :country_code, :postal_code, :state, :treat_line_2_as_addressee,
  :treat_line_3_as_addressee, :country_name, :email_address, :phone_number

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
    validates :email_address, if: :email_required?
    validates :phone_number, if: :phone_number_required?
  end
  validate :name, unless: :person?
  # code that checks if a vbms_distribution with held params are valid?

  EXPECTED_PARAMS_FOR_RECIPIENTS_AND_DESTINATIONS = [
                                                      :recipient_type,
                                                      :name,
                                                      :first_name,
                                                      :middle_name,
                                                      :last_name,
                                                      :participant_id,
                                                      :poa_code,
                                                      :claimant_station_of_jurisdiction,
                                                      :destination_type,
                                                      :address_line_1,
                                                      :address_line_2,
                                                      :address_line_3,
                                                      :address_line_4,
                                                      :address_line_5,
                                                      :address_line_6,
                                                      :city,
                                                      :country_code,
                                                      :postal_code,
                                                      :state,
                                                      :treat_line_2_as_addressee,
                                                      :treat_line_3_as_addressee,
                                                      :country_name,
                                                      :email_address,
                                                      :phone_number
                                                    ].freeze

  def initialize(params)
    @params = params.permit(EXPECTED_PARAMS_FOR_RECIPIENTS_AND_DESTINATIONS)
    @recipient_type = @params[:recipient_type]
    @name = @params[:name]
    @first_name = @params[:first_name]
    @middle_name = @params[:middle_name]
    @last_name = @params[:last_name]
    @participant_id = @params[:participant_id]
    @poa_code = @params[:poa_code]
    @claimant_station_of_jurisdiction = @params[:claimant_station_of_jurisdiction]
    @destination_type = @params[:destination_type]
    @address_line_1 = @params[:address_line_1]
    @address_line_2 = @params[:address_line_2]
    @address_line_3 = @params[:address_line_3]
    @address_line_4 = @params[:address_line_4]
    @address_line_5 = @params[:address_line_5]
    @address_line_6 = @params[:address_line_6]
    @city = @params[:city]
    @country_code = @params[:country_code]
    @postal_code = @params[:postal_code]
    @state = @params[:state]
    @treat_line_2_as_addressee = @params[:treat_line_2_as_addressee]
    @treat_line_3_as_addressee = @params[:treat_line_3_as_addressee]
    @country_name = @params[:country_name]
    @email_address = @params[:email_address]
    @phone_number = @params[:phone_number]
  end

  def call
    byebug
    if valid?
      create_a_vbms_distribution
      create_a_vbms_distribution_destination
    else
      raise Caseflow::Error::MissingRecipientInfo
    end
  end

  def create_a_vbms_distribution
    VbmsDistribution.create(recipient_params_parse)
  end

  def create_a_vbms_distribution_destination
    VbmsDistributionDestination.create(destination_params_parse)
  end

  private

  def recipient_type_valid?
    unless @params[:recipient_type].blank?
      valid_var = %w[organization person system ro-colocated].include?(
        @params[:recipient_type].slice(1, @params[:recipient_type].length - 2))
      valid_var
    end
  end

  def person?
    unless @params[:recipient_type].blank?
      @params[:recipient_type].slice(1, @params[:recipient_type].length - 2) == "person"
    end
  end

  def ro_colocated?
    unless @params[:recipient_type].blank?
      @params[:recipient_type].slice(1, @params[:recipient_type].length - 2) == "ro-colocated"
    end
  end

  def destination_type_valid?
    unless @params[:destination_type].blank?
      %w[domesticAddress internationalAddress militaryAddress derived email sms].include?(
        @params[:destination_type].slice(1, @params[:destination_type].length - 2)
      )
    end
  end

  def physical_mail?
    unless @params[:destination_type].blank?
      %w[domesticAddress internationalAddress militaryAddress].include?(
        @params[:destination_type].slice(1, @params[:destination_type].length - 2)
      )
    end
  end

  def line_2_addressee?
    unless @params[:treat_line_2_as_addressee].blank?
      @params[:treat_line_2_as_addressee] == true
    end
  end

  def line_3_addressee?
    unless @params[:treat_line_3_as_addressee].blank?
      @params[:treat_line_3_as_addressee] == true
    end
  end

  def country_name_required?
    unless @params[:destination_type].blank?
      @params[:destination_type].slice(1, @params[:destination_type].length - 2) == "internationalAddress"
    end
  end

  def us_address?
    unless @params[:destination_type].blank?
      %w[domesticAddress militaryAddress].include?(
        @params[:destination_type].slice(1, @params[:destination_type].length - 2)
      )
    end
  end

  def email_required?
    unless @params[:destination_type].blank?
      @params[:destination_type].slice(1, @params[:destination_type].length - 2) == "email"
    end
  end

  def phone_number_required?
    unless @params[:destination_type].blank?
      @params[:destination_type].slice(1, @params[:destination_type].length - 2) == "sms"
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
      country_code: @country,
      postal_code: @postal_code,
      state: @state,
      treat_line_2_as_addressee: @treat_line_2_as_addressee,
      treat_line_3_as_addressee: @treat_line_3_as_addressee,
      country_name: @country_name,
      email_address: @email_address,
      phone_number: @phone_number
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
