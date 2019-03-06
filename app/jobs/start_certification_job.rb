# frozen_string_literal: true

class StartCertificationJob < ApplicationJob
  queue_as :high_priority
  attr_accessor :certification
  application_attr :certification

  def perform(certification, user = nil)
    @certification = certification
    RequestStore.store[:current_user] = user if user

    # Results in calls to VBMS and VACOLS

    if @certification.can_be_updated?
      @certification.create_or_update_form8
      update_certification_attributes
    end
    fetch_power_of_attorney! if @certification.certification_status == :started
    update_data_complete
  rescue StandardError => e
    Rails.logger.info "StartCertificationJob failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    update_data_failed
  end

  private

  def update_certification_attributes
    user = RequestStore[:current_user]
    @certification.update!(
      already_certified: @certification.calculate_already_certified,
      vacols_data_missing: @certification.calculate_vacols_data_missing,
      nod_matching_at: @certification.calculate_nod_matching_at,
      form9_matching_at: @certification.calculate_form9_matching_at,
      soc_matching_at: @certification.calculate_soc_matching_at,
      ssocs_required: @certification.calculate_ssocs_required,
      ssocs_matching_at: @certification.calculcate_ssocs_matching_at,
      form8_started_at: (@certification.certification_status == :started) ? @certification.now : nil,
      vacols_hearing_preference: @certification.appeal.hearing_request_type,
      certifying_office: @certification.appeal.regional_office_name,
      certifying_username: @certification.appeal.regional_office_key,
      certifying_official_name: user ? user.full_name : nil
    )
  end

  def update_data_complete
    @certification.update!(
      loading_data: false,
      loading_data_failed: false
    )
  end

  def update_data_failed
    @certification.update!(
      loading_data: false,
      loading_data_failed: true
    )
  end

  def fetch_power_of_attorney!
    poa = @certification.appeal.power_of_attorney
    update = {
      bgs_representative_type: poa.bgs_representative_type,
      bgs_representative_name: poa.bgs_representative_name,
      vacols_representative_type: poa.vacols_representative_type,
      vacols_representative_name: poa.vacols_representative_name
    }

    address = poa.bgs_representative_address
    if address
      update = update.merge(bgs_rep_address_line_1: address[:address_line_1],
                            bgs_rep_address_line_2: address[:address_line_2],
                            bgs_rep_address_line_3: address[:address_line_3],
                            bgs_rep_city: address[:city],
                            bgs_rep_country: address[:country],
                            bgs_rep_state: address[:state],
                            bgs_rep_zip: address[:zip])
    end

    @certification.update!(update)
  end

  # This job will run again if the user reloads the browser.
  # We don't want to retry it otherwise.
  def max_attempts
    1
  end
end
