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
      if should_create_or_update_virtual_hearing?
        create_or_update_virtual_hearing
        hearing.reload
        start_async_job
        add_virtual_hearing_alert
      end
    end
  end

  def hearing_alerts
    @hearing_alerts ||= []
  end

  def virtual_hearing_alert
    @virtual_hearing_alert ||= {}
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

  def datadog_metric_info
    {
      app_name: RequestStore[:application],
      metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME
    }
  end

  def show_update_alert?
    # if user only changes the hearing time for a virtual hearing, don't show update alert
    # scheduled_time for hearing, scheduled_for for legacy
    return false if hearing.virtual? && hearing_updates.except(:scheduled_time, :scheduled_for).empty?

    hearing_updated?
  end

  def should_create_or_update_virtual_hearing?
    # If any are true:
    #   1. Any virtual hearing attributes are set
    #   2. Hearing time is being changed
    #   3. Judge is being changed
    return true if virtual_hearing_attributes.present?

    if hearing.virtual?
      return scheduled_time_string.present? || judge_id.present?
    end

    false
  end

  def only_time_updated?
    !virtual_hearing_created? && scheduled_time_string.present?
  end

  def start_async_job?
    (hearing.virtual_hearing.pending? || !hearing.virtual_hearing.all_emails_sent?) &&
      !hearing.virtual_hearing.cancelled?
  end

  def start_async_job
    return if !start_async_job?

    hearing.virtual_hearing.establishment.submit_for_processing!

    job_args = {
      hearing_id: hearing.id,
      hearing_type: hearing.class.name,
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

  def updates_requiring_email?
    virtual_hearing_attributes&.key?(:status) || scheduled_time_string.present?
  end

  def veteran_email_sent_flag
    !(updates_requiring_email? || virtual_hearing_attributes&.key?(:veteran_email))
  end

  def representative_email_sent_flag
    !(updates_requiring_email? || virtual_hearing_attributes&.key?(:representative_email))
  end

  # also returns false if the judge id is present or true if the virtual hearing is being cancelled
  def judge_email_sent_flag
    flag = !(updates_requiring_email? || virtual_hearing_attributes&.key?(:judge_email) || judge_id.present?)
    flag || virtual_hearing_cancelled?
  end

  def virtual_hearing_cancelled?
    virtual_hearing_attributes&.dig(:status) == "cancelled"
  end

  def virtual_hearing_updates
    # The email sent flag should always be set to false if any changes are made.
    # The judge_email_sent flag should not be set to false if virtual hearing is cancelled.
    emails_sent_updates = {
      veteran_email_sent: veteran_email_sent_flag,
      judge_email_sent: judge_email_sent_flag,
      representative_email_sent: representative_email_sent_flag
    }.reject { |_k, email_sent| email_sent == true }

    updates = (virtual_hearing_attributes || {}).compact.merge(emails_sent_updates)

    if judge_id.present?
      updates[:judge_email] = hearing.judge&.email
    end

    updates
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

    updated_metric_info = datadog_metric_info.merge(attrs: { hearing_id: hearing&.id })

    if !virtual_hearing_created?
      virtual_hearing.update(virtual_hearing_updates)
      virtual_hearing.establishment.restart!
      DataDogService.increment_counter(metric_name: "updated_virtual_hearing.successful", **updated_metric_info)
    else
      VirtualHearingEstablishment.create!(virtual_hearing: virtual_hearing)
      DataDogService.increment_counter(metric_name: "created_virtual_hearing.successful", **updated_metric_info)
    end
  end

  def add_update_hearing_alert
    hearing_alerts << UserAlert.new(
      title: COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % veteran_full_name,
      type: UserAlert::TYPES[:success]
    ).to_hash
  end

  def veteran_full_name
    @veteran_full_name ||= hearing.appeal&.veteran&.name&.to_s || "the veteran"
  end

  def only_emails_updated?
    email_changed = virtual_hearing_attributes&.key?(:veteran_email) ||
                    virtual_hearing_attributes&.key?(:representative_email) ||
                    judge_id.present?

    email_changed && !virtual_hearing_cancelled? && !virtual_hearing_created?
  end

  def email_change_type
    if virtual_hearing_attributes&.key?(:veteran_email) && virtual_hearing_attributes&.key?(:representative_email)
      "CHANGED_VETERAN_AND_POA_EMAIL"
    elsif virtual_hearing_attributes&.key?(:veteran_email)
      "CHANGED_VETERAN_EMAIL"
    elsif virtual_hearing_attributes&.key?(:representative_email)
      "CHANGED_POA_EMAIL"
    elsif judge_id.present?
      "CHANGED_VLJ_EMAIL"
    end
  end

  def change_type
    if virtual_hearing_created?
      "CHANGED_TO_VIRTUAL"
    elsif virtual_hearing_cancelled?
      "CHANGED_FROM_VIRTUAL"
    elsif only_time_updated?
      "CHANGED_HEARING_TIME"
    elsif only_emails_updated?
      email_change_type
    end
  end

  def add_virtual_hearing_alert
    nested_alert = VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :info,
      veteran_full_name: veteran_full_name
    ).call.to_hash

    nested_alert[:next] = VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :success,
      veteran_full_name: veteran_full_name
    ).call.to_hash

    @virtual_hearing_alert = nested_alert
  end
end
