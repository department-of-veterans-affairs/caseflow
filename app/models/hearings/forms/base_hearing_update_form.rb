# frozen_string_literal: true

##
# BaseHearingUpdateForm accepts params from HearingUpdateForm (AMA Hearings) and LegacyHearingUpdateForm.
# It's responsible for deciding how Caseflow should act on those updates. Actions that BaseHearingUpdateForm
# can trigger include:
# - Update/Create to Hearing/LegacyHearing
# - Update/Create/Delete VirtualHearing (VirtualHearings::*)
# - Update/Create/Delete EmailRecipient(s)
# - Send/resend emails to EmailRecipient(s)
# - Display alert banners on the form used to change the hearing (change_type)
##
class BaseHearingUpdateForm
  include ActiveModel::Model
  include RunAsyncable

  attr_accessor :bva_poc, :disposition,
                :hearing, :hearing_location_attributes, :hold_open,
                :judge_id, :military_service, :notes, :prepped,
                :representative_name, :room, :scheduled_time_string,
                :summary, :transcript_requested, :virtual_hearing_attributes,
                :witness, :email_recipients_attributes

  def update
    ActiveRecord::Base.multi_transaction do
      update_hearing

      add_update_hearing_alert if show_update_alert?
      create_or_update_virtual_hearing if should_create_or_update_virtual_hearing?

      after_update_hearing
    end
    # reload hearing so new virtual hearing changes are visible
    hearing.reload

    email_sent_updates!

    start_async_job if start_async_job?

    add_virtual_hearing_alert if show_virtual_hearing_progress_alerts?
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

  def custom_metric_info
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
    [
      appellant_email_sent_flag,
      representative_email_sent_flag,
      judge_email_sent_flag
    ].any?(false) && (hearing.virtual? || virtual_hearing_cancelled?)
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

  it "should update scheduled_datetime if it is not null already" do
    date_str = "#{hearing.hearing_day.scheduled_for} America/New_York"
    is_dst = Time.zone.parse(date_str).dst?

    hearing.update(
      scheduled_datetime: "2021-04-23T11:30:00#{is_dst ? '-04:00' : '-05:00'}",
      scheduled_in_timezone: "America/New_York"
    )
    subject.update
    updated_scheduled_datetime = hearing.scheduled_datetime

    expect(updated_scheduled_datetime.strftime("%Y-%m-%d %H:%M %z"))
      .to eq "#{hearing.hearing_day.scheduled_for.strftime('%Y-%m-%d')} 21:45 #{is_dst ? '-0400' : '-0500'}"
  end

  def start_async_job?
    hearing.virtual_hearing.present? && !hearing.virtual_hearing.all_emails_sent?
  end

  def start_async_job
    # If converting hearing from virtual to non-virtual
    if start_async_job? && virtual_hearing_cancelled?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
      maybe_start_activate_non_virtual_job
    # If converting hearing from non-virtual to virtual
    elsif start_async_job?
      start_activate_virtual_job
    end
  end

  # If a Webex hearing, activate new Webex conference links when converting from virtual to non-virtual
  def maybe_start_activate_non_virtual_job
    return unless hearing.conference_provider == "webex"

    perform_later_or_now(Hearings::CreateNonVirtualConferenceJob, hearing: hearing)
  end

  def start_activate_virtual_job
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
                        appellant_email.present? ||
                        appellant_timezone.present?

    # Note: Don't set flag if hearing disposition is cancelled, postponed, or scheduled in error
    !should_send_email || hearing.postponed_or_cancelled_or_scheduled_in_error?
  end

  def appellant_email
    email_recipient_attributes = hearing_updates.fetch(:email_recipients_attributes, {}).find do |_, att|
      att.fetch("email_address", nil).present? && att.fetch("type", nil) == "AppellantHearingEmailRecipient"
    end&.last

    email = email_recipient_attributes&.fetch("email_address", nil) || virtual_hearing_attributes&.[](:appellant_email)

    email&.strip
  end

  def representative_email
    email_recipient_attributes = hearing_updates.fetch(:email_recipients_attributes, {}).find do |_, att|
      att.fetch("email_address", nil).present? && att.fetch("type", nil) == "RepresentativeHearingEmailRecipient"
    end&.last

    email = email_recipient_attributes&.fetch("email_address", nil) ||
            virtual_hearing_attributes&.[](:representative_email)

    email&.strip
  end

  def appellant_timezone
    email_recipient_attributes = hearing_updates.fetch(:email_recipients_attributes, {}).find do |_, att|
      att.fetch("timezone", nil).present? && att.fetch("type", nil) == "AppellantHearingEmailRecipient"
    end&.last

    email = email_recipient_attributes&.fetch("timezone", nil) || virtual_hearing_attributes&.[](:appellant_tz)

    email&.strip
  end

  def representative_timezone
    email_recipient_attributes = hearing_updates.fetch(:email_recipients_attributes, {}).find do |_, att|
      att.fetch("timezone", nil).present? && att.fetch("type", nil) == "RepresentativeHearingEmailRecipient"
    end&.last

    email = email_recipient_attributes&.fetch("timezone", nil) || virtual_hearing_attributes&.[](:representative_tz)

    email&.strip
  end

  def judge_email
    hearing.judge&.email
  end

  # Send rep email if cancelling, updating time or updating either rep email or rep timezone
  def representative_email_sent_flag
    should_send_email = updates_requiring_email? ||
                        representative_email.present? ||
                        representative_timezone.present?

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
    @virtual_hearing_attributes = virtual_hearing_attributes || {}
    emails_sent_updates = {
      appellant_email_sent: appellant_email_sent_flag,
      judge_email_sent: judge_email_sent_flag,
      representative_email_sent: representative_email_sent_flag
    }.reject { |_k, email_sent| email_sent == true }

    updates = virtual_hearing_attributes.merge(emails_sent_updates)

    if judge_id.present?
      updates[:judge_email] = judge_email
    end

    updates
  end

  def email_sent_updates!
    if hearing.appellant_recipient.present?
      hearing.appellant_recipient.update(
        email_sent: appellant_email_sent_flag
      )
    end
    if hearing.representative_recipient.present?
      hearing.representative_recipient.update(
        email_sent: representative_email_sent_flag
      )
    end
    if hearing.judge_recipient.present?
      hearing.judge_recipient.update(
        email_sent: judge_email_sent_flag
      )
    end
  end

  def virtual_hearing_updates
    @virtual_hearing_updates ||= define_virtual_hearing_updates
  end

  def virtual_hearing_created?
    @virtual_hearing_created ||= false
  end

  def update_appellant_recipient
    update_params = {
      email_address: appellant_email.presence,
      timezone: appellant_timezone.presence,
      email_sent: virtual_hearing_updates&.key?(:appellant_email_sent) ? false : true
    }.compact

    hearing.appellant_recipient.update!(**update_params) if update_params.any?
  end

  def update_representative_recipient
    if representative_email.present?
      hearing.create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email
      )
    end

    if hearing.representative_recipient.present?
      update_params = {
        timezone: representative_timezone.presence,
        email_sent: virtual_hearing_updates&.key?(:representative_email_sent) ? false : true
      }.compact

      hearing.representative_recipient.update!(**update_params) if update_params.any?
    end
  end

  def update_judge_recipient
    if judge_email.present?
      hearing.create_or_update_recipients(
        type: JudgeHearingEmailRecipient,
        email_address: judge_email
      )
    end

    if hearing.judge_recipient.present?
      update_params = {
        email_sent: virtual_hearing_updates&.key?(:judge_email_sent) ? false : true
      }.compact

      hearing.judge_recipient.update!(**update_params) if update_params.any?
    end
  end

  def update_email_recipients
    update_appellant_recipient
    update_representative_recipient
    update_judge_recipient
  end

  # rubocop:disable Metrics/MethodLength
  def create_or_update_email_recipients
    if appellant_email.present?
      hearing.create_or_update_recipients(
        type: AppellantHearingEmailRecipient,
        email_address: appellant_email,
        timezone: appellant_timezone
      )
    end

    if representative_email.present?
      hearing.representative_recipient&.unset_email_address!
      hearing.create_or_update_recipients(
        type: RepresentativeHearingEmailRecipient,
        email_address: representative_email,
        timezone: representative_timezone
      )
    end

    if judge_email.present?
      hearing.judge_recipient&.unset_email_address!
      hearing.create_or_update_recipients(
        type: JudgeHearingEmailRecipient,
        email_address: judge_email,
        timezone: nil
      )
    end
  end
  # rubocop:enable Metrics/MethodLength

  def create_or_update_virtual_hearing
    # TODO: All of this is not atomic :(. Revisit later, since Rails 6 offers an upsert.
    virtual_hearing = VirtualHearing.not_cancelled.find_or_create_by!(hearing: hearing) do
      create_or_update_email_recipients

      @virtual_hearing_created = true
    end

    # Merge the hearing ID into the DataDog metrics
    updated_metric_info = custom_metric_info.merge(attrs: { hearing_id: hearing&.id })

    # Handle the status toggle of the virtual hearing
    if virtual_hearing_cancelled?
      virtual_hearing.update!(request_cancelled: true)
      update_email_recipients
      MetricsService.increment_counter(metric_name: "cancelled_virtual_hearing.successful", **updated_metric_info)
    elsif !virtual_hearing_created?
      virtual_hearing.establishment.restart!
      update_email_recipients
      MetricsService.increment_counter(metric_name: "updated_virtual_hearing.successful", **updated_metric_info)
    else
      VirtualHearingEstablishment.create!(virtual_hearing: virtual_hearing)
      MetricsService.increment_counter(metric_name: "created_virtual_hearing.successful", **updated_metric_info)
    end
  end

  def only_emails_updated?
    email_changed = appellant_email.present? ||
                    representative_email.present? ||
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
