class StartCertificationJob < ActiveJob::Base
  queue_as :high_priority
  attr_accessor :certification, :user

  def perform(certification, user = nil, ip_address = nil)
    @certification = certification
    @user = user

    RequestStore.store[:current_user] = user if user
    # Passing in ip address since it's only available when
    # the session is.
    RequestStore.store[:ip_address] = ip_address if ip_address
    # Results in calls to VBMS and VACOLS

    if @certification.can_be_updated?
      create_or_update_form8
      update_certification_attributes
    end
    fetch_power_of_attorney! if @certification.certification_status == :started
  rescue => e
    Rails.logger.info "StartCertificationJob failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
    update_data_failed
  end

  private

  def update_certification_attributes
    @certification.update_attributes!(
      already_certified:   calculate_already_certified,
      vacols_data_missing: calculate_vacols_data_missing,
      nod_matching_at:     calculate_nod_matching_at,
      form9_matching_at:   calculate_form9_matching_at,
      soc_matching_at:     calculate_soc_matching_at,
      ssocs_required:      calculate_ssocs_required,
      ssocs_matching_at:   calculcate_ssocs_matching_at,
      form8_started_at:    (@certification.certification_status == :started) ? now : nil,
      vacols_hearing_preference: appeal.hearing_request_type,
      certifying_office: appeal.regional_office_name,
      certifying_username: appeal.regional_office_key,
      certifying_official_name: @user ? @user.full_name : nil,
      certification_date: Time.zone.now.to_date,
      loading_data: false,
      loading_data_failed: false
    )
  end

  def update_data_failed
    @certification.update_attributes!(
      loading_data: false,
      loading_data_failed: true
    )
  end

  def fetch_power_of_attorney!
    poa = appeal.power_of_attorney
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

    @certification.update_attributes!(update)
  end

  def create_or_update_form8
    # if we haven't yet started the form8
    # or if we last updated it earlier than 48 hours ago,
    # refresh it with new data.
    if !form8 || form8.updated_at < 48.hours.ago
      @form8 ||= Form8.new(certification_id: @certification.id)
      @form8.assign_attributes_from_appeal(appeal)
      @form8.save!
    else
      form8.update_certification_date
    end
  end

  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(@certification.vacols_id)
  end

  def form8
    @form8 ||= Form8.find_by(certification_id: @certification.id)
  end

  def now
    @now ||= Time.zone.now
  end

  def calculate_form9_matching_at
    appeal.form9.try(:matching?) ? (@certification.form9_matching_at || now) : nil
  end

  def calculate_already_certified
    certification.already_certified || appeal.certified?
  end

  def calculate_vacols_data_missing
    certification.vacols_data_missing || appeal.missing_certification_data?
  end

  def calculate_nod_matching_at
    appeal.nod.try(:matching?) ? (@certification.nod_matching_at || now) : nil
  end

  def calculate_soc_matching_at
    appeal.soc.try(:matching?) ? (@certification.soc_matching_at || now) : nil
  end

  def calculcate_ssocs_matching_at
    (calculate_ssocs_required && appeal.ssocs.all?(&:matching?)) ? (@certification.ssocs_matching_at || now) : nil
  end

  def calculate_ssocs_required
    appeal.ssocs.any?
  end

  # This job will run again if the user reloads the browser.
  # We don't want to retry it otherwise.
  def max_attempts
    1
  end
end
