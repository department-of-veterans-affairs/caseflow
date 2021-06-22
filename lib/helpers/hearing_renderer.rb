# frozen_string_literal: true

class HearingRenderer
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    HearingDay
    Appeal
    LegacyAppeal
    Hearing
    LegacyHearing
    HearingTask
    VirtualHearing
  ].freeze

  # use these characters instead of '/', which TTY:Tree can't render
  SLASH_CHARACTERS = "|"

  class << self
    def render(obj, show_pii: false)
      renderer = HearingRenderer.new(show_pii: show_pii)
      TTY::Tree.new(renderer.structure(obj, include_breadcrumbs: true)).render
    end

    def renderable_classes
      RENDERABLE_CLASSNAMES.map(&:constantize)
    end

    def prefix(obj)
      klass_to_prefix = renderable_classes.find { |klass| obj.is_a?(klass) }
      klass_to_prefix&.name&.underscore
    end

    def patch_hearing_classes
      renderable_classes.each { |klass| klass.include HearingRenderable }
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

  def veteran_details(veteran)
    details = []
    details += [veteran.name, "FN: #{veteran.file_number}"] if show_pii
    details << "PID: #{veteran.participant_id}"
    details
  end

  def readable_date(date, include_time = true)
    if include_time
      date.strftime("%m-%d-%Y %-I:%M%p %Z")
    else
      date.strftime("%m-%d-%Y")
    end
  end

  def readable_time(datetime)
    datetime.strftime("%-I:%M%p %Z")
  end

  def veteran_children(veteran)
    appeals = Appeal.where(veteran_file_number: veteran.file_number)
    appeals.sort_by { |appeal| appeal.receipt_date || Time.zone.today }
    legacy_appeals = LegacyAppeal.fetch_appeals_by_file_number(veteran.file_number)
    legacy_appeals.sort_by { |la| la.created_at || Time.zone.today }

    (appeals + legacy_appeals).map { |appeal| structure(appeal) }
  end

  def hearing_day_details(hearing_day)
    [format_hearing_day_label(hearing_day)]
  end

  def hearing_day_children(hearing_day)
    hearing_day.hearings.map { |hearing| structure(hearing) }
  end

  def appeal_type_conversions(appeal)
    unformatted_versions = appeal.versions
    versions = unformatted_versions.map do |version|
      change = version.changeset["changed_hearing_request_type"] ||
               version.changeset["changed_request_type"]
      {
        "from_type" => print_nil(Hearing::HEARING_TYPES[change[0]&.to_sym]),
        "to_type" => Hearing::HEARING_TYPES[change[1]&.to_sym],
        "converted_by" => User.find(version.whodunnit).css_id,
        "converted_at" => readable_date(version.created_at)
      }
    end

    versions
  end

  def format_original_and_current_type(appeal)
    original = print_nil(appeal.readable_original_hearing_request_type)
    current = print_nil(appeal.readable_current_hearing_request_type)
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

  def appeal_history(appeal)
    if appeal.versions.empty?
      format_original_and_current_type(appeal)
    else
      type_conversions = appeal_type_conversions(appeal)
      type_conversions_with_original_type = add_original_type(
        appeal.readable_original_hearing_request_type,
        type_conversions
      )
      text = format_original_and_current_type(appeal)
      text += format_conversions(type_conversions_with_original_type)
      text
    end
  end

  def notes_or_include_pii_info(notes)
    return if notes.blank?
    return notes if show_pii

    "pass 'show_pii: true' to see notes"
  end

  def unscheduled_hearings(appeal)
    open_schedule_hearing_tasks = appeal.tasks.open.of_type(:ScheduleHearingTask)
    return [] if open_schedule_hearing_tasks.empty?

    ro_label = ro_location(appeal.closest_regional_office)

    unscheduled_hearings = open_schedule_hearing_tasks.map do |sh_task|
      unscheduled_hearing_label = "Unscheduled Hearing (SCH Task ID: #{sh_task.id}, RO queue: #{ro_label})"
      instructions = sh_task.parent&.instructions

      unscheduled_notes = notes_or_include_pii_info(instructions)
      if unscheduled_notes.present?
        { unscheduled_hearing_label => ["Notes: #{unscheduled_notes}"] }
      else
        unscheduled_hearing_label
      end
    end

    unscheduled_hearings
  end

  def shared_appeal_children(appeal)
    children = []
    if appeal.appellant_is_not_veteran
      children << "Appellant is not veteran - #{appeal&.appellant_relationship}"
    end

    children += appeal.hearings.map { |hearing| structure(hearing) }
    children += unscheduled_hearings(appeal)

    children << {
      "Appeal History": appeal_history(appeal)
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
    time_in_ro_zone = hearing.scheduled_for.in_time_zone(hearing.regional_office_timezone)
    time_in_eastern = hearing.scheduled_for.in_time_zone("Eastern Time (US & Canada)")

    scheduled_label = "Scheduled for: #{readable_date(time_in_eastern)}"

    if time_in_ro_zone.zone != time_in_eastern.zone
      scheduled_label = "#{scheduled_label} #{SLASH_CHARACTERS} #{readable_time(time_in_ro_zone)} (RO time)"
    end

    scheduled_label
  end

  def print_nil(obj)
    obj.presence || "none"
  end

  def ro_location(regional_office)
    RegionalOffice.city_state_by_key(regional_office).presence&.tr(",", "") || COPY::UNKNOWN_REGIONAL_OFFICE
  end

  def ro_label(regional_office, request_type = nil)
    about_ro = regional_office.blank? ? "No RO" : "#{regional_office} - #{ro_location(regional_office)}"
    about_request = Hearing::HEARING_TYPES[request_type&.to_sym]&.presence || "No request type"

    [about_ro, about_request].join(", ")
  end

  def format_hearing_day_label(hearing_day)
    return "No hearing day" if hearing_day.nil?

    formatted_text = "HearingDay #{hearing_day.id}"
    formatted_text += " (#{ro_label(hearing_day.regional_office, hearing_day.request_type)}"
    formatted_text += ", VLJ #{hearing_day.judge&.full_name&.split(' ')&.last}" if hearing_day.judge.present?
    formatted_text + ")"
  end

  def format_hearing_label(hearing)
    hearing_type = print_nil(hearing.readable_request_type)
    disposition = hearing.disposition.nil? ? "no disposition" : hearing.disposition
    coordinator = hearing.bva_poc.nil? ? "no coordinator" : hearing.bva_poc

    "#{hearing_type}, #{disposition}, #{coordinator}"
  end

  def shared_hearing_children(hearing)
    virtual_hearings = VirtualHearing.where(hearing_id: hearing.id, hearing_type: hearing.class.name)
    children = [
      scheduled_for(hearing),
      format_hearing_label(hearing),
      format_hearing_day_label(hearing.hearing_day),
      virtual_hearings.map { |vh| structure(vh) }
    ].flatten

    hearing_notes = notes_or_include_pii_info(hearing.notes)
    children.unshift("Notes: #{hearing_notes}") unless hearing_notes.nil?

    if hearing.email_events.present?
      children << {
        "Email events": hearing.email_events.map do |ev|
          "#{readable_date(ev.sent_at, false)}, "\
            "#{ev.email_type}, #{ev.recipient_role}"
        end
      }
    end
    children << structure(hearing&.hearing_task_association&.hearing_task)
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
    instructions = notes_or_include_pii_info(hearing_task.instructions)
    children << "Instr: #{instructions}" unless instructions.nil?

    children += hearing_task.children.map do |ct|
      if ct.is_a?(ScheduleHearingTask) || ct.is_a?(AssignHearingDispositionTask)
        "#{ct.class.name} #{ct.id} (#{ct.status}, ca: #{readable_date(ct.created_at)})"
      end
    end

    children
  end

  def hearing_task_details(hearing_task)
    ["#{hearing_task.status}, ca: #{readable_date(hearing_task.created_at)}"]
  end

  def hearing_task_context(hearing_task)
    hearing_task.appeal
  end

  def email_sent(flag)
    flag ? "email sent" : "email not sent"
  end

  def virtual_hearing_children(virtual_hearing)
    recipients = []

    if virtual_hearing.appellant_email.present?
      recipients << "appellant - #{email_sent(virtual_hearing.appellant_email_sent)}"
    end

    if virtual_hearing.representative_email.present?
      recipients << "rep - #{email_sent(virtual_hearing.representative_email_sent)}"
    end

    if virtual_hearing.judge_email.present?
      recipients << "judge - #{email_sent(virtual_hearing.judge_email_sent)}"
    end

    [recipients.join(", ")]
  end

  def virtual_hearing_details(virtual_hearing)
    status = virtual_hearing.status
    created_at = readable_date(virtual_hearing.created_at)
    created_by = virtual_hearing.created_by&.css_id

    ["#{status}, ca: #{created_at}, #{created_by}"]
  end

  def virtual_hearing_context(virtual_hearing)
    virtual_hearing.hearing
  end
end
