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
    virtual_hearing_changed = false

    ActiveRecord::Base.multi_transaction do
      update_hearing
      add_update_hearing_alert if show_update_alert?
      if should_create_or_update_virtual_hearing?
        create_or_update_virtual_hearing

        virtual_hearing_changed = true
      end

      after_update_hearing
    end

    if virtual_hearing_changed
      # reload hearing so new virtual hearing changes are visible
      hearing.reload

      start_async_job

      add_virtual_hearing_alert if show_virtual_hearing_progress_alerts?
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

  def after_update_hearing; end

  def hearing_updates; end

  # Whether or not the hearing has been updated by the form.
  #
  # @return [Boolean]
  #   True if there is at least one non-nil and non-empty key in the hearing updates
  def hearing_updated?
    hearing_updates.each_value do |value|
      return true unless [nil, {}, []].include?(value)
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
    return false if hearing.virtual? && (hearing_updates.dig(:scheduled_time).present? ||
                    hearing_updates.dig(:scheduled_for).present?)

    hearing_updated? || (virtual_hearing_updates.present? && !show_virtual_hearing_progress_alerts?)
  end

  def show_virtual_hearing_progress_alerts?
    [appellant_email_sent_flag, representative_email_sent_flag, judge_email_sent_flag].any?(false)
  end

  def should_create_or_update_virtual_hearing?
    virtual_hearing = hearing&.virtual_hearing

    # If there's a job running, the virtual hearing shouldn't be changed.
    if virtual_hearing&.pending? || virtual_hearing&.job_completed? == false
      add_virtual_hearing_job_running_alert

      return false
    end

    # If any are true:
    #   1. Any virtual hearing attributes are set
    #   2. Hearing time is being changed
    #   3. Judge is being changed
    (
      virtual_hearing_attributes.present? ||
      (hearing.virtual? && (scheduled_time_string.present? || judge_id.present?))
    )
  end

  def only_time_updated_or_timezone_updated?
    # Always false if the virtual hearing was just created or if any emails were changed
    if virtual_hearing_created? || virtual_hearing_attributes&.keys&.any? do |attribute|
         %w[appellant_email representative_email].include? attribute
       end
      return false
    end

    # True if hearing time was updated
    scheduled_time_string.present? ||
      # True if the representative timezone or appellant timezone is changed
      virtual_hearing_attributes&.dig(:representative_tz).present? ||
      virtual_hearing_attributes&.dig(:appellant_tz).present?
  end

  def start_async_job?
    !hearing.virtual_hearing.all_emails_sent?
  end

  def start_async_job
    if start_async_job? && virtual_hearing_cancelled?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    elsif start_async_job?
      start_activate_job
    end
  end

  def start_activate_job
    hearing.virtual_hearing.establishment.submit_for_processing!

    job_args = {
      hearing_id: hearing.id,
      hearing_type: hearing.class.name,
      # TODO: Ideally, this would use symbols, but symbols can't be serialized for ActiveJob.
      # Rails 6 supports passing symbols to a job.
      email_type: only_time_updated_or_timezone_updated? ? "updated_time_confirmation" : "confirmation"
    }

    perform_later_or_now(VirtualHearings::CreateConferenceJob, job_args)
  end

  def updates_requiring_email?
    virtual_hearing_attributes&.key?(:request_cancelled) || scheduled_time_string.present?
  end

  # Send appellant email if cancelling, updating time or updating either appellant email or appellant timezone
  def appellant_email_sent_flag
    should_send_email = updates_requiring_email? ||
                        virtual_hearing_attributes&.key?(:appellant_email) ||
                        virtual_hearing_attributes&.key?(:appellant_tz)

    # Note: Don't set flag if hearing disposition is cancelled, postponed, or scheduled in error
    !should_send_email || hearing.postponed_or_cancelled_or_scheduled_in_error?
  end

  def appellant_email
    virtual_hearing_attributes&.fetch(:appellant_email, nil)&.strip
  end

  def representative_email
    virtual_hearing_attributes&.fetch(:representative_email, nil)&.strip
  end

  def judge_email
    hearing.judge&.email
  end

  # Send rep email if cancelling, updating time or updating either rep email or rep timezone
  def representative_email_sent_flag
    should_send_email = updates_requiring_email? ||
                        representative_email.present? ||
                        virtual_hearing_attributes&.key?(:representative_tz)

    # Note: Don't set flag if hearing disposition is cancelled, postponed, or scheduled in error
    !should_send_email || hearing.postponed_or_cancelled_or_scheduled_in_error?
  end

  # also returns false if the judge id is present or true if the virtual hearing is being cancelled
  def judge_email_sent_flag
    should_send_email = updates_requiring_email? ||
                        judge_id.present? ||
                        virtual_hearing_attributes&.key?(:judge_email)

    # Note: Don't set flag if hearing disposition is cancelled, postponed, or scheduled in error
    !should_send_email || virtual_hearing_cancelled? || hearing.postponed_or_cancelled_or_scheduled_in_error?
  end

  def virtual_hearing_cancelled?
    virtual_hearing_attributes&.dig(:request_cancelled) == true
  end

  def define_virtual_hearing_updates
    # The email sent flag should always be set to false if any changes are made.
    # The judge_email_sent flag should not be set to false if virtual hearing is cancelled.
    emails_sent_updates = {
      appellant_email_sent: appellant_email_sent_flag,
      judge_email_sent: judge_email_sent_flag,
      representative_email_sent: representative_email_sent_flag
    }.reject { |_k, email_sent| email_sent == true }

    updates = (virtual_hearing_attributes || {}).merge(emails_sent_updates)

    if judge_id.present?
      updates[:judge_email] = judge_email
    end

    updates
  end

  def virtual_hearing_updates
    @virtual_hearing_updates ||= define_virtual_hearing_updates
  end

  def virtual_hearing_created?
    @virtual_hearing_created ||= false
  end

  def update_appellant_recipient
    if appellant_email.present?
      hearing.appellant_recipient.update!(email_address: appellant_email)
    end

    if virtual_hearing_updates[:appellant_tz].present?
      hearing.appellant_recipient.update!( timezone: virtual_hearing_updates[:appellant_tz])
    end

    if virtual_hearing_updates.key?(:appellant_email_sent)
      hearing.appellant_recipient.update!(email_sent: virtual_hearing_updates[:appellant_email_sent])
    end
  end

  def update_representative_recipient
    if representative_email.present?
      hearing.create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email
      )
    end

    if hearing.representative_recipient.present? && virtual_hearing_updates[:representative_tz].present?
      hearing.representative_recipient.update!(timezone: virtual_hearing_updates[:representative_tz])
    end

    if virtual_hearing_updates.key?(:representative_email_sent)
      hearing.representative_recipient.update!(email_sent: virtual_hearing_updates[:representative_email_sent])
    end
  end

  def update_judge_recipient
    if judge_email.present?
      hearing.create_or_update_recipients(
        type: JudgeHearingEmailRecipient,
        email_address: judge_email
      )
    end

    if virtual_hearing_updates.key?(:judge_email_sent)
      hearing.judge_recipient.update!(email_sent: virtual_hearing_updates[:judge_email_sent])
    end
  end

  def update_email_recipients
    update_appellant_recipient
    update_representative_recipient
    update_judge_recipient
  end

  def create_or_update_email_recipients
    hearing.create_or_update_recipients(
      type: AppellantHearingEmailRecipient,
      email_address: appellant_email,
      timezone: virtual_hearing_updates[:appellant_tz]
    )

    hearing.representative_recipient&.unset_email_address!
    if representative_email.present?
      hearing.create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email,
        timezone: virtual_hearing_updates[:representative_tz]
      )
    end

    hearing.judge_recipient&.unset_email_address!
    if judge_email.present?
      hearing.create_or_update_recipients(
        type: JudgeHearingEmailRecipient,
        email_address: judge_email,
        timezone: nil
      )
    end
  end

  def create_or_update_virtual_hearing
    # TODO: All of this is not atomic :(. Revisit later, since Rails 6 offers an upsert.
    virtual_hearing = VirtualHearing.not_cancelled.find_or_create_by!(hearing: hearing) do
      create_or_update_email_recipients

      @virtual_hearing_created = true
    end

    # Merge the hearing ID into the DataDog metrics
    updated_metric_info = datadog_metric_info.merge(attrs: { hearing_id: hearing&.id })

    # Handle the status toggle of the virtual hearing
    if virtual_hearing_cancelled?
      virtual_hearing.update!(request_cancelled: true)
      update_email_recipients
      DataDogService.increment_counter(metric_name: "cancelled_virtual_hearing.successful", **updated_metric_info)
    elsif !virtual_hearing_created?
      update_email_recipients
      virtual_hearing.establishment.restart!
      DataDogService.increment_counter(metric_name: "updated_virtual_hearing.successful", **updated_metric_info)
    else
      VirtualHearingEstablishment.create!(virtual_hearing: virtual_hearing)
      DataDogService.increment_counter(metric_name: "created_virtual_hearing.successful", **updated_metric_info)
    end
  end

  def only_emails_updated?
    email_changed = virtual_hearing_attributes&.key?(:appellant_email) ||
                    virtual_hearing_attributes&.key?(:representative_email) ||
                    judge_id.present?

    email_changed && !virtual_hearing_cancelled? && !virtual_hearing_created?
  end

  def change_type
    if virtual_hearing_created?
      "CHANGED_TO_VIRTUAL"
    elsif virtual_hearing_cancelled?
      "CHANGED_FROM_VIRTUAL"
    elsif only_time_updated_or_timezone_updated?
      "CHANGED_HEARING_TIME"
    elsif only_emails_updated?
      "CHANGED_EMAIL"
    end
  end

  def add_update_hearing_alert
    veteran_full_name = hearing.appeal&.veteran&.name || "the veteran"

    hearing_alerts << UserAlert.new(
      title: COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % veteran_full_name,
      type: UserAlert::TYPES[:success]
    ).to_hash
  end

  def add_virtual_hearing_job_running_alert
    alert_key = if hearing.virtual_hearing.updated_by != RequestStore[:current_user]
                  "ANOTHER_USER_IS_UPDATING"
                else
                  "JOB_IS_RUNNING"
                end

    hearing_alerts << UserAlert.new(
      title: COPY::VIRTUAL_HEARING_ERROR_ALERTS[alert_key]["TITLE"],
      message: COPY::VIRTUAL_HEARING_ERROR_ALERTS[alert_key]["MESSAGE"],
      type: UserAlert::TYPES[:error]
    )
  end

  def add_virtual_hearing_alert
    nested_alert = VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :info,
      hearing: hearing,
      virtual_hearing_updates: virtual_hearing_updates
    ).call.to_hash

    nested_alert[:next] = VirtualHearingUserAlertBuilder.new(
      change_type: change_type,
      alert_type: :success,
      hearing: hearing,
      virtual_hearing_updates: virtual_hearing_updates
    ).call.to_hash

    @virtual_hearing_alert = nested_alert
  end
end
