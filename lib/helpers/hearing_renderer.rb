# frozen_string_literal: true

class HearingRenderer
  # Actually, we want to start this from the appeal
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    Appeal
    Hearing
    HearingTask
    ScheduleHearingTask
    AssignHearingDispositionTask
    HearingDay
    VirtualHearing
  ].freeze

  class << self
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

  def veteran_children(vet)
    appeals = Appeal.where(veteran_file_number: vet.file_number)
    appeals.sort_by { |appeal| appeal.receipt_date || Time.zone.today }
    appeals.map { |appeal| structure(appeal) }
  end

  def appeal_details(appeal)
    ["appeal details stub #{appeal.id}"]
  end

  def appeal_children(appeal)
    children = []
    children << appeal.hearings.map { |hearing| structure(hearing) }
    children << { "Appellant": ["Appellant is not veteran", "Relationship to veteran: spouse"] }
    children << { "History": { "Hearing Request Type": ["Converted to Virtual from Video  by `BVASYELLOW` at [Datetime]", "Converted to Video from Central  by `BVASYELLOW` at [Datetime]"] } }

    children
  end

  def appeal_context(appeal)
    appeal.veteran
  end

  def hearing_children(hearing)
    children = []
    children << structure(hearing.hearing_task)
    children << "Notes example notes"
    children << "Scheduled Time: 05012021 8:30 AM EDT 5:30 PST (RO time)"
    children << "type: Virtual, disp: held, HC: BVASYELLOW"
    children << { "HearingDay [id]": "hearing day info" }
    virtual_hearings = VirtualHearing.where(hearing_id: hearing.id, hearing_type: hearing.class.name)
    children << virtual_hearings.map { |vh| structure(vh) }
    children << { "Email Events": ["Appellant, confirmation, id23134", "Representative, confirmation, id4234"] }

    children
  end

  def hearing_details(hearing)
    ["hearing details stub #{hearing.id}"]
  end

  def hearing_context(hearing)
    hearing.appeal
  end

  def hearing_task_children(hearing_task)
    children = []
    children += hearing_task.children.of_type("ScheduleHearingTask")
    children += hearing_task.children.of_type("AssignHearingDispositionTask")
    children += hearing_task.children.of_type("AssignHearingDispositionTask")

    children
  end

  def hearing_task_details(hearing_task)
    ["root_task details stub #{hearing_task.id}"]
  end

  def hearing_task_context(hearing_task)
    hearing_task.appeal
  end

  def virtual_hearing_children(virtual_hearing)
    children = []
    children << "Appellant - email sent, Rep - email sent, Judge - email not sent"
    children << "Scheduled by BVASYELLOW at 5012021"

    children
  end

  def virtual_hearing_details(virtual_hearing)
    ["VirtualHearing [ID] (Status: Pending)"]
  end

  def virtual_hearing_context(virtual_hearing)
    virtual_hearing.hearing
  end
end
