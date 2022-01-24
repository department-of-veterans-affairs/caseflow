# frozen_string_literal: true

class MpiController < ApplicationController
  def index; end

  def mpi
    @mpi ||= MPIService.new
  end

  def search
    results = mpi.search_people_info(
      last_name: params[:last_name],
      first_name: params[:first_name],
      middle_name: params[:middle_name].presence,
      ssn: params[:ssn].presence,
      date_of_birth: date_of_birth_param,
      gender: params[:gender].presence,
      address: address_param,
      telephone: params[:telephone].presence
    )

    formatted_results = results.map { |res| MpiController.print_patient(res[:registration_event][:subject1][:patient]) }

    render json: formatted_results
  rescue MPI::QueryError, Savon::SOAPFault => error
    render json: { error: error.class.name }, status: :unprocessable_entity
  end

  class << self
    def print_patient(hash)
      person = hash[:patient_person]
      {
        name: format_name(person),
        ssn: format_ssn(person),
        birthdate: format_birthtime(person),
        gender: format_gender(person),
        phone: format_phone(person),
        address: format_address(person),
        status: format_status(hash)
      }.compact
    end

    def format_name(person)
      name = [person[:name]].flatten.find { |hash| hash[:@use] == "L" } # legal name only
      given_names = [name[:given]].flatten.join(" ")
      "#{name[:family]}, #{given_names}"
    end

    def format_status(hash)
      hash[:status_code][:@code].to_s
    end

    def format_phone(person)
      phone = person&.dig(:telecom, :@value)
      phone.to_s if phone.present?
    end

    def format_gender(person)
      gender = person&.dig(:administrative_gender_code, :@code)
      gender.to_s if gender.present?
    end

    def format_ssn(person)
      other_ids = [person[:as_other_i_ds]].flatten
      ssns = other_ids.select { |other_id| other_id[:@class_code] == "SSN" }
        .map { |other_id| other_id.dig(:id, :@extension) }.compact
      ssn = ssns[0].dup
      ssn.gsub("SSN: ", "").to_s if ssns.any?
    end

    def format_birthtime(person)
      birthtime = person&.dig(:birthtime, :@value)
      birthtime.to_s if birthtime.present?
    end

    def format_address(person)
      address = person&.dig(:addr)
      "#{value[:street_address_line]}, #{address[:city]} #{value[:state]} #{address[:postal_code]}" if address.present?
    end
  end

  def address_param
    {
      street: [params[:addressLine1], params[:addressLine2]].compact.join(" ").presence,
      city: params[:city].presence,
      state: params[:state].presence,
      postal_code: params[:zip].presence,
      country: params[:country].presence
    }.compact.presence
  end

  def date_of_birth_param
    params[:date_of_birth][0..9].delete("-")
  end
end
