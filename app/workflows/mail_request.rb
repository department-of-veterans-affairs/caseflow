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


  EXPECTED_PARAMS_FOR_RECIPIENTS_AND_DESTINATIONS = [
                                                      recipient_info:[
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
                                                      :country_name
                                                      ]].freeze

  def initialize(params)
    @params = params.permit(
      :veteran_identifier,
      :document_subject,
      :document_name,
      :file,
      :document_type,
      recipient_info:[
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
      :country_name]).to_h
    # @recipient_info_hash = @params[:recipient_info]
    @recipient_type = @params[:recipient_info][0][:recipient_type]
    @name = @params[:recipient_info][0][:name]
    @first_name = @params[:recipient_info][0][:first_name]
    @middle_name = @params[:recipient_info][0][:middle_name]
    @last_name = @params[:recipient_info][0][:last_name]
    @participant_id = @params[:recipient_info][0][:participant_id]
    @poa_code = @params[:recipient_info][0][:poa_code]
    @claimant_station_of_jurisdiction = @params[:recipient_info][0][:claimant_station_of_jurisdiction]
    @destination_type = @params[:recipient_info][0][:destination_type]
    @address_line_1 = @params[:recipient_info][0][:address_line_1]
    @address_line_2 = @params[:recipient_info][0][:address_line_2]
    @address_line_3 = @params[:recipient_info][0][:address_line_3]
    @address_line_4 = @params[:recipient_info][0][:address_line_4]
    @address_line_5 = @params[:recipient_info][0][:address_line_5]
    @address_line_6 = @params[:recipient_info][0][:address_line_6]
    @city = @params[:recipient_info][0][:city]
    @country_code = @params[:recipient_info][0][:country_code]
    @postal_code = @params[:recipient_info][0][:postal_code]
    @state = @params[:recipient_info][0][:state]
    @treat_line_2_as_addressee = @params[:recipient_info][0][:treat_line_2_as_addressee]
    @treat_line_3_as_addressee = @params[:recipient_info][0][:treat_line_3_as_addressee]
    @country_name = @params[:recipient_info][0][:country_name]
    @vbms_distribution_id = nil
    @comm_package_id = nil
  end

  def call
    if valid?
      distribution = create_a_vbms_distribution
      byebug
      @vbms_distribution_id = distribution.id
      byebug
      destination = create_a_vbms_distribution_destination
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
      # vbms_communication_package_id: 3

    }
  end
end
