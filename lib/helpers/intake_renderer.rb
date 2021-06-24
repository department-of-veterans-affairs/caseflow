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

  def veteran_details(vet)
    details = []
    details += [vet.name, "FN: #{vet.file_number}"] if show_pii
    details << "PID: #{vet.participant_id}"
    details
  end

  # :nocov:
  def veteran_children(vet)
    reviews = [Appeal, HigherLevelReview, SupplementalClaim].map do |klass|
      klass.where(veteran_file_number: vet.file_number)
    end.flatten
    reviews.sort_by! { |dr| dr.receipt_date || Time.zone.today }
    reviews.map { |dr| structure(dr) }
  end
  # :nocov:

  def decision_review_details(dr)
    ["rcvd #{dr.receipt_date.to_s}", dr.uuid]
  end

  def decision_review_children(dr)
    children = []
    children << "est. err: #{truncate(dr.establishment_error, 60)}" if dr.establishment_error.present?
    children << (structure(dr.claimant) || "no claimant")
    children << (structure(dr.intake) || "no intake")

    epes = dr.try(:end_product_establishments)&.to_a
    other_ris = dr.request_issues.where(end_product_establishment: nil).map { |ri| structure(ri) }
    if epes.present?
      children += epes.map { |epe| structure(epe) }
      children << { "other issues:": other_ris } if other_ris.present?
    else
      children += other_ris
    end

    children += dr.request_issues_updates.map { |riu| structure(riu) }
    children += dr.decision_issues.map { |di| structure(di) }

    children
  end

  def decision_review_context(dr)
    dr.veteran
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
    children += epe.request_issues.map { |ri| structure(ri) }
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

  def request_issue_details(ri)
    details = [ri.benefit_type]
    details << if ri.rating?
                 "rating"
               elsif ri.nonrating?
                 "nonrating"
               elsif ri.verified_unidentified_issue?
                 "verified unidentified"
               else
                 "unidentified"
               end
    details
  end

  def request_issue_children(ri)
    children = []
    children << "descr: #{truncate(ri.description, 55)}"
    children << "#{ri.nonrating_issue_category} - #{ri.nonrating_issue_description}" if ri.nonrating?
    if ri.contention_reference_id
      contention = "Contention #{ri.contention_reference_id}"
      contention += " (disp: #{ri.contention_disposition.disposition})" if ri.contention_disposition
      children << contention
    end
    children << "corrected by: #{label(ri.correction_request_issue)}" if ri.corrected?
    if ri.ineligible_reason.present?
      child = "ineligible (#{ri.ineligible_reason})"
      if ri.ineligible_due_to_id.present?
        child = {
          "#{child}" => ["due to #{label(ri.ineligible_due_to)}"]
        }
      end
      children << child
    end
    children += ri.decision_issues.map { |di| label(di) }
    history = request_issue_history(ri)
    children << { "history:": history } if history.present?
    children
  end

  def request_issue_history(ri)
    history = [
      [ri.created_at, "created"],
      [ri.closed_at, "closed: #{ri.closed_status}"],
      [ri.rating_issue_associated_at, "rating issue associated"],
      [ri.contention_removed_at, "contention removed"],
      [ri.contention_updated_at, "contention updated"],
      [ri.decision_sync_attempted_at, "decision sync attempted"],
      [ri.decision_sync_canceled_at, "decision sync canceled"]
    ]
    history.select { |hi| hi[0].present? }.map { |hi| "#{hi[0].to_s}: #{hi[1]}" }.sort
  end

  def request_issue_context(ri)
    ri.end_product_establishment || ri.decision_review
  end

  def request_issues_update_children(riu)
    children = ["performed by: #{label(riu.user)}"]
    %w[added removed withdrawn edited correction].each do |update_type|
      issues = riu.send("#{update_type}_issues")
      if issues.present?
        children << { "#{update_type}:": issues.map { |ri| label(ri) } }
      end
    end
    children << "error: #{truncate(riu.error, 60)}" if riu.error.present?
    children
  end

  def request_issues_update_context(riu)
    riu.review
  end

  def decision_issue_details(di)
    [di.disposition]
  end

  def decision_issue_children(di)
    ["descr: #{truncate(di.description, 60)}"] + di.request_issues.map { |ri| label(ri) }
  end

  def decision_issue_context(di)
    di.decision_review
  end

  def user_details(user)
    [user.css_id]
  end

  def truncate(text, size)
    (text.size > size) ? text[0, size - 1] + "…" : text if text
  end
  # :nocov:
end
