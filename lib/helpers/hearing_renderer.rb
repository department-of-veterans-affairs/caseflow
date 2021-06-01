# frozen_string_literal: true

class HearingRenderer
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    Appeal
    RootTask
    User
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
    children = [structure(appeal.root_task)]
    children
  end

  def appeal_context(appeal)
    appeal.veteran
  end

  def root_task_children(root_task)
    root_task.children.of_type("DistributionTask")
  end

  def root_task_details(root_task)
    ["root_task details stub #{root_task.id}"]
  end

  def root_task_context(root_task)
    root_task.appeal
  end
end
