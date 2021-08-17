# frozen_string_literal: true

class IntakeRenderer
  RENDERABLE_CLASSNAMES = %w[
    Veteran
    DecisionReview
    Claimant
    Intake
    EndProductEstablishment
    RequestIssue
    RequestIssuesUpdate
    DecisionIssue
    User
  ].freeze

  class << self
    def render(obj, show_pii: false)
      renderer = IntakeRenderer.new(show_pii: show_pii)
      TTY::Tree.new(renderer.structure(obj, include_breadcrumbs: true)).render
    end

    def renderable_classes
      RENDERABLE_CLASSNAMES.map(&:constantize)
    end

    def prefix(obj)
      klass = renderable_classes.find { |k| obj.is_a?(k) }
      klass&.name&.underscore
    end

    def patch_intake_classes
      renderable_classes.each { |klass| klass.include IntakeRenderable }
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

  # :nocov:
  def veteran_children(veteran)
    reviews = [Appeal, HigherLevelReview, SupplementalClaim].map do |klass|
      klass.where(veteran_file_number: veteran.file_number)
    end.flatten
    reviews.sort_by! { |decision_review| decision_review.receipt_date || Time.zone.today }
    reviews.map { |decision_review| structure(decision_review) }
  end
  # :nocov:

  def decision_review_details(decision_review)
    ["rcvd #{decision_review.receipt_date.to_s}", decision_review.uuid]
  end

  def decision_review_children(decision_review)
    children = []
    if decision_review.establishment_error.present?
      children << "est. err: #{truncate(decision_review.establishment_error, 60)}"
    end
    children << (structure(decision_review.claimant) || "no claimant")
    children << (structure(decision_review.intake) || "no intake")

    epes = decision_review.try(:end_product_establishments)&.to_a
    other_ris = decision_review.request_issues.where(end_product_establishment: nil).map do |request_issue|
      structure(request_issue)
    end
    if epes.present?
      children += epes.map { |epe| structure(epe) }
      children << { "other issues:": other_ris } if other_ris.present?
    else
      children += other_ris
    end

    children += decision_review.request_issues_updates.map { |riu| structure(riu) }
    children += decision_review.decision_issues.map { |decision_issue| structure(decision_issue) }

    children
  end

  def decision_review_context(decision_review)
    decision_review.veteran
  end

  def claimant_details(claimant)
    details = []
    if claimant.name.blank?
      details << "Name unknown"
    elsif show_pii
      details << claimant.name
    end
    details << "PID: #{claimant.participant_id}"
    details << "payee: #{claimant.payee_code || 'nil'}" if claimant.decision_review.processed_in_vbms?
    details
  end

  # :nocov:
  def claimant_context(claimant)
    claimant.decision_review
  end

  def intake_children(intake)
    ["performed by: #{label(intake.user)}"]
  end

  def intake_context(intake)
    intake.detail
  end

  def end_product_establishment_details(epe)
    [epe.code, "mod: #{epe.modifier || 'nil'}", epe.synced_status]
  end

  def end_product_establishment_children(epe)
    children = []
    children << "Claim #{epe.reference_id}" if epe.reference_id.present?
    children += epe.request_issues.map { |request_issue| structure(request_issue) }
    history = end_product_establishment_history(epe)
    children << { "history:": history } if history.present?
    children
  end

  def end_product_establishment_history(epe)
    history = [
      [epe.created_at, "created"],
      [epe.established_at, "established"],
      [epe.last_synced_at, "last synced: #{epe.synced_status || 'nil'}"]
    ]
    history.select { |hi| hi[0].present? }.map { |hi| "#{hi[0].to_s}: #{hi[1]}" }.sort
  end

  def end_product_establishment_context(epe)
    epe.source
  end

  def request_issue_details(request_issue)
    details = [request_issue.benefit_type]
    details << if request_issue.rating?
                 "rating"
               elsif request_issue.nonrating?
                 "nonrating"
               elsif request_issue.verified_unidentified_issue?
                 "verified unidentified"
               else
                 "unidentified"
               end
    details
  end

  def request_issue_children(request_issue)
    children = []
    children << "descr: #{truncate(request_issue.description, 55)}"
    if request_issue.nonrating?
      children << "#{request_issue.nonrating_issue_category} - #{request_issue.nonrating_issue_description}"
    end
    if request_issue.contention_reference_id
      contention = "Contention #{request_issue.contention_reference_id}"
      if request_issue.contention_disposition
        contention += " (disp: #{request_issue.contention_disposition.disposition})"
      end
      children << contention
    end
    children << "corrected by: #{label(request_issue.correction_request_issue)}" if request_issue.corrected?
    if request_issue.ineligible_reason.present?
      child = "ineligible (#{request_issue.ineligible_reason})"
      if request_issue.ineligible_due_to_id.present?
        child = {
          "#{child}" => ["due to #{label(request_issue.ineligible_due_to)}"]
        }
      end
      children << child
    end
    children += request_issue.decision_issues.map { |decision_issue| label(decision_issue) }
    history = request_issue_history(request_issue)
    children << { "history:": history } if history.present?
    children
  end

  def request_issue_history(request_issue)
    history = [
      [request_issue.created_at, "created"],
      [request_issue.closed_at, "closed: #{request_issue.closed_status}"],
      [request_issue.rating_issue_associated_at, "rating issue associated"],
      [request_issue.contention_removed_at, "contention removed"],
      [request_issue.contention_updated_at, "contention updated"],
      [request_issue.decision_sync_attempted_at, "decision sync attempted"],
      [request_issue.decision_sync_canceled_at, "decision sync canceled"]
    ]
    history.select { |hi| hi[0].present? }.map { |hi| "#{hi[0].to_s}: #{hi[1]}" }.sort
  end

  def request_issue_context(request_issue)
    request_issue.end_product_establishment || request_issue.decision_review
  end

  def request_issues_update_children(riu)
    children = ["performed by: #{label(riu.user)}"]
    %w[added removed withdrawn edited correction].each do |update_type|
      issues = riu.send("#{update_type}_issues")
      if issues.present?
        children << { "#{update_type}:": issues.map { |request_issue| label(request_issue) } }
      end
    end
    children << "error: #{truncate(riu.error, 60)}" if riu.error.present?
    children
  end

  def request_issues_update_context(riu)
    riu.review
  end

  def decision_issue_details(decision_issue)
    [decision_issue.disposition]
  end

  def decision_issue_children(decision_issue)
    labels = decision_issue.request_issues.map { |request_issue| label(request_issue) }
    ["descr: #{truncate(decision_issue.description, 60)}"] + labels
  end

  def decision_issue_context(decision_issue)
    decision_issue.decision_review
  end

  def user_details(user)
    [user.css_id]
  end

  def truncate(text, size)
    if text
      (text.size > size) ? text[0, size - 1] + "…" : text
    end
  end
  # :nocov:
end
