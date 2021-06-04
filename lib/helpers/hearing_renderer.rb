# frozen_string_literal: true

class HearingRenderer
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    Appeal
    LegacyAppeal
    Hearing
    LegacyHearing
    HearingTask
    ScheduleHearingTask
    AssignHearingDispositionTask
    VirtualHearing
  ].freeze

  class << self
    def test_veteran_with_ama
      ama_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: Hearing.name).last
      veteran_with_ama_hearing = ama_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_ama_hearing)
    end

    def test_veteran_with_legacy
      legacy_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: LegacyHearing.name).last
      veteran_with_legacy_hearing = legacy_virtual_hearing.hearing.appeal.veteran
      puts render(veteran_with_legacy_hearing)
    end

    def test_breadcrumbs
      ama_virtual_hearing = VirtualHearing.not_cancelled.where(hearing_type: Hearing.name).last
      puts render(ama_virtual_hearing.hearing)
    end

    def render(obj, show_pii: false)
      renderer = HearingRenderer.new(show_pii: show_pii)
      TTY::Tree.new(renderer.structure(obj, include_breadcrumbs: true)).render
    end

    def renderable_classes
      RENDERABLE_CLASSNAMES.map(&:constantize)
    end

    def prefix(obj)
      klass = renderable_classes.find { |k| obj.is_a?(k) }
      klass&.name&.underscore
    end
  end

  attr_reader :show_pii

  def initialize(show_pii: false)
    @show_pii = show_pii
  end

  def structure(obj, include_breadcrumbs: false)
    return if obj.nil?

    children = try("#{self.class.prefix(obj)}_children", obj)&.compact || []
    if include_breadcrumbs
      context = calculate_breadcrumbs(obj)
      children << { "breadcrumbs:": context } if context.present?
    end
    { "#{label(obj)}": children }
  end

  def label(obj)
    return "nil" if obj.nil?

    result = "#{obj.class.name} #{obj.id}"
    details = try("#{self.class.prefix(obj)}_details", obj)&.compact
    result += " (#{details.join(', ')})" if details.present?
    result
  end

  def calculate_breadcrumbs(obj)
    context = try("#{self.class.prefix(obj)}_context", obj)
    return [] if context.blank?

    [label(context), calculate_breadcrumbs(context)].flatten
  end

  def veteran_details(vet)
    details = []
    details += [vet.name, "FN: #{vet.file_number}"] if show_pii
    details << "PID: #{vet.participant_id}"
    details
  end

  def readable_date_in_est(date)
  end

  def veteran_children(vet)
    appeals = Appeal.where(veteran_file_number: vet.file_number)
    appeals.sort_by { |a| a.receipt_date || Time.zone.today }
    legacy_appeals = LegacyAppeal.fetch_appeals_by_file_number(vet.file_number)
    legacy_appeals.sort_by { |la| la.created_at || Time.zone.today }

    children = []
    children += legacy_appeals.map { |legacy_appeal| structure(legacy_appeal) }
    children += appeals.map { |appeal| structure(appeal) }
    children
  end

  def get_appeal_type_conversions(appeal)
    unformatted_versions = appeal.versions
    versions = unformatted_versions.map do |v|
      change = v.changeset["changed_hearing_request_type"]
      {
        "from_type" => Hearing::HEARING_TYPES[change[0]&.to_sym],
        "to_type" => Hearing::HEARING_TYPES[change[1]&.to_sym],
        "converted_by" => User.find(v.whodunnit).css_id,
        "converted_at" => v.created_at
      }
    end

    versions
  end

  # TODO, use the nil to "None" converter that's being added
  def format_original_and_current_type(appeal)
    original = appeal.readable_original_hearing_request_type
    current = appeal.readable_current_hearing_request_type
    if original == current && appeal.versions.count == 0
      ["Current type: #{current}"]
    else
      ["Original Type: #{original}, current type: #{current}"]
    end
  end

  def format_conversions(type_conversions)
    type_conversions.map do |tc|
      "Converted to #{tc['to_type']} from #{tc['from_type']} by #{tc['converted_by']} at #{tc['converted_at']}"
    end
  end

  def add_original_type(original_type, type_conversions)
    first_conversion = type_conversions[0]
    first_conversion["from_type"] = original_type
    type_conversions[0] = first_conversion

    type_conversions
  end

  def get_appeal_history(appeal)
    if appeal.versions.empty?
      format_original_and_current_type(appeal)
    else
      type_conversions = get_appeal_type_conversions(appeal)
      type_conversions_with_original_type = add_original_type(
        appeal.readable_original_hearing_request_type,
        type_conversions
      )
      text = format_original_and_current_type(appeal)
      text += format_conversions(type_conversions_with_original_type)
      text
    end
  end

  def shared_appeal_children(appeal)
    children = []
    if appeal.appellant_is_not_veteran
      children << "Appellant is not veteran - #{appeal&.appellant_relationship}"
    end

    children += appeal.hearings.map { |hearing| structure(hearing) }
    # TODO: HearingTask subtree

    # TODO: create list of type conversion history from Papertrail
    # TODO: remove Hearing Request Type subheader
    children << {
      "History": get_appeal_history(appeal)
    }
    children
  end

  def legacy_appeal_details(legacy_appeal)
    ["VACOLS ID: #{legacy_appeal.vacols_id}"]
  end

  def legacy_appeal_children(legacy_appeal)
    shared_appeal_children(legacy_appeal)
  end

  def legacy_appeal_context(legacy_appeal)
    legacy_appeal.veteran
  end

  def appeal_details(appeal)
    ["UUID: #{appeal.uuid}"]
  end

  def appeal_children(appeal)
    shared_appeal_children(appeal)
  end

  def appeal_context(appeal)
    appeal.veteran
  end

  def scheduled_for(hearing)
    ro_time = hearing.scheduled_for.in_time_zone(hearing.regional_office_timezone)
    if ro_time != hearing.scheduled_for
      "Scheduled for: #{hearing.scheduled_for.strftime("%m-%d-%Y %I:%M%p %Z")} / #{ro_time.strftime("%I:%M%p %Z")}(RO time)"
    end

    "Scheduled for: #{hearing.scheduled_for.strftime("%m-%d-%Y %I:%M%p %Z")}"
  end

  def shared_hearing_children(hearing)
    children = []
    children << "Notes: #{hearing.notes}" if hearing.notes.present? && show_pii
    ro_time = hearing.scheduled_for.in_time_zone(hearing.regional_office_timezone).strftime("%I:%M%p %Z")
    children << scheduled_for(hearing)
    children << "Type: #{hearing.readable_request_type}, Disp: #{hearing.disposition}, HC: #{hearing.bva_poc}"
    children << "HearingDay #{hearing.hearing_day.id} (Docket: #{hearing.hearing_day.id})"

    virtual_hearings = VirtualHearing.where(hearing_id: hearing.id, hearing_type: hearing.class.name)
    children += virtual_hearings.map { |vh| structure(vh) }
    children << {
      "Email Events": hearing.email_events.map do |ev|
        "#{ev.recipient_role}, #{ev.email_type}, #{ev.sent_at}, #{ev.external_message_id}"
      end
    }
  end

  def legacy_hearing_children(hearing)
    shared_hearing_children(hearing)
  end

  def legacy_hearing_details(hearing)
    ["VACOLS ID: #{hearing.vacols_id}"]
  end

  def legacy_hearing_context(hearing)
    hearing.appeal
  end

  def hearing_children(hearing)
    shared_hearing_children(hearing)
  end

  def hearing_details(hearing)
    ["UUID: #{hearing.uuid}"]
  end

  def hearing_context(hearing)
    hearing.appeal
  end

  def hearing_task_children(hearing_task)
    children = []
    # status,
    children += hearing_task.children.of_type("ScheduleHearingTask")
    children += hearing_task.children.of_type("AssignHearingDispositionTask")
    children += hearing_task.children.of_type("AssignHearingDispositionTask")

    children
  end

  def hearing_task_details(hearing_task)
    ["#{hearing_task.status}, #{hearing_task.created_at}, #{hearing_task.updated_at}"]
  end

  def hearing_task_context(hearing_task)
    hearing_task.appeal
  end

  def email_sent(flag)
    flag ? "email sent" : "email not sent"
  end

  def virtual_hearing_children(virtual_hearing)
    children = []
    recipients = []
    recipients << "Appellant - #{email_sent(virtual_hearing.appellant_email_sent)} "if virtual_hearing.appellant_email.present?
    recipients << "Rep - #{email_sent(virtual_hearing.representative_email_sent)} " if virtual_hearing.representative_email.present?
    recipients << "Judge - #{email_sent(virtual_hearing.judge_email_sent)}" if virtual_hearing.judge_email.present?
    children << recipients.join
    children << "Scheduled by #{virtual_hearing.created_by&.css_id} at #{virtual_hearing.created_at}"

    children
  end

  def virtual_hearing_details(virtual_hearing)
    ["#{virtual_hearing.status}"]
  end

  def virtual_hearing_context(virtual_hearing)
    virtual_hearing.hearing
  end
end
