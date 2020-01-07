# frozen_string_literal: true

class BaseHearingUpdateForm
  include ActiveModel::Model
  include RunAsyncable

  attr_accessor :bva_poc, :disposition,
                :hearing, :hearing_location_attributes, :hold_open,
                :judge_id, :military_service, :notes, :prepped,
                :representative_name, :room, :scheduled_time_string,
                :summary, :transcript_requested, :virtual_hearing_attributes,
                :witness

  def update
    ActiveRecord::Base.transaction do
      update_hearing
      add_update_hearing_alert if show_update_alert?
      if virtual_hearing_form_or_hearing_time_was_updated?
        create_or_update_virtual_hearing
        hearing.reload
        start_async_job
        add_virtual_hearing_alert
      end
    end
  end

  def alerts
    @alerts ||= []
  end

  protected

  def update_hearing; end

  def hearing_updates; end

  def hearing_updated?
    hearing_updates.each_key do |key|
      return true if hearing_updates.dig(key).present?
    end
    false
  end

  private

  def show_update_alert?
    # if user only changes the hearing time for a virtual hearing, don't show update alert
    return false if hearing.virtual? && hearing_updates.except(:scheduled_time).empty?

    hearing_updated?
  end

  def virtual_hearing_form_or_hearing_time_was_updated?
    !virtual_hearing_attributes.blank? || (hearing.virtual? && scheduled_time_string.present?)
  end

  def only_time_updated?
    !virtual_hearing_created? && scheduled_time_string.present?
  end

  def start_async_job
    if hearing.virtual_hearing.status == "pending" || !hearing.virtual_hearing.all_emails_sent?
      hearing.virtual_hearing.establishment.submit_for_processing!

      job_args = {
        hearing_id: hearing.id,
        # TODO: Ideally, this would use symbols, but symbols can't be serialized for ActiveJob.
        # Rails 6 supports passing symbols to a job.
        email_type: only_time_updated? ? "updated_time_confirmation" : "confirmation"
      }

      if run_async?
        VirtualHearings::CreateConferenceJob.perform_later(job_args)
      else
        VirtualHearings::CreateConferenceJob.perform_now(job_args)
      end
    end
  end

  def email_sent_flag(attr_key)
    status_changed = virtual_hearing_attributes.key?(:status)

    !(status_changed || virtual_hearing_attributes.key?(attr_key) || scheduled_time_string.present?)
  end

  def virtual_hearing_created?
    @virtual_hearing_created ||= false
  end

  def create_or_update_virtual_hearing
    # TODO: All of this is not atomic :(. Revisit later, since Rails 6 offers an upsert.
    virtual_hearing = VirtualHearing.not_cancelled.find_or_create_by!(hearing: hearing) do |new_virtual_hearing|
      new_virtual_hearing.veteran_email = virtual_hearing_attributes[:veteran_email]
      new_virtual_hearing.judge_email = hearing.judge&.email
      new_virtual_hearing.representative_email = virtual_hearing_attributes[:representative_email]
      @virtual_hearing_created = true
    end

    if !virtual_hearing_created?
      # The email sent flag should always be set to false from the API.
      emails_sent_updates = {
        veteran_email_sent: email_sent_flag(:veteran_email),
        judge_email_sent: email_sent_flag(:judge_email),
        representative_email_sent: email_sent_flag(:representative_email)
      }.reject { |_k, email_sent| email_sent == true }

      updates = virtual_hearing_attributes.compact.merge(emails_sent_updates)

      virtual_hearing.update(updates)
      virtual_hearing.establishment.restart!
    else
      VirtualHearingEstablishment.create!(virtual_hearing: virtual_hearing)
    end
  end

  def add_virtual_hearing_alert
    alerts << VirtualHearingUserAlertBuilder.new(
      changed_to_virtual: virtual_hearing_created?,
      virtual_hearing_attributes: virtual_hearing_attributes,
      veteran_full_name: veteran_full_name,
      hearing_time_changed: scheduled_time_string.present?
    ).call.to_hash
  end

  def add_update_hearing_alert
    alerts << UserAlert.new(
      title: COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % veteran_full_name,
      type: UserAlert::TYPES[:success]
    ).to_hash
  end

  def veteran_full_name
    @veteran_full_name ||= hearing.appeal&.veteran&.name&.to_s || "the veteran"
  end
end
