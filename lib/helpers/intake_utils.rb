# frozen_string_literal: true

module IntakeUtils
  def render(obj)
    TTY::Tree.new(intake_structure(obj, include_breadcrumbs: true)).render
  end

  def renderable_prefix(obj)
    known_types = [
      Veteran,
      DecisionReview,
      Intake,
      EndProductEstablishment,
      RequestIssue,
      RequestIssuesUpdate]
    klass = known_types.find { |k| obj.is_a?(k) }
    klass&.name&.underscore
  end

  def intake_structure(obj, include_breadcrumbs: false)
    label = renderable_label(obj)
    prefix = renderable_prefix(obj)
    children = try("#{prefix}_children", obj) || []
    if include_breadcrumbs
      context = calculate_breadcrumbs(obj)
      children << { "breadcrumbs:": context } if context.present?
    end
    children.present? ? { "#{label}": children } : label
  end

  def renderable_label(obj)
    prefix = renderable_prefix(obj)
    label = try("#{prefix}_label", obj)
    label.present? ? label : "#{obj.class.name} #{obj.id}"
  end

  def calculate_breadcrumbs(obj)
    context = try("#{renderable_prefix(obj)}_context", obj)
    return [] unless context.present?

    [renderable_label(context), calculate_breadcrumbs(context)].flatten
  end

  def veteran_label(vet)
    "Veteran #{vet.id}"
  end

  def veteran_children(vet)
    reviews = [Appeal, HigherLevelReview, SupplementalClaim].map do |klass|
      klass.where(veteran_file_number: vet.file_number)
    end.flatten.sort_by { |dr| dr.receipt_date || Time.zone.today }
    reviews.map { |dr| intake_structure(dr) }
  end

  def decision_review_label(dr)
    "#{dr.class.name} #{dr.id} (#{dr.receipt_date.to_s}, #{dr.uuid})"
  end

  def decision_review_children(dr)
    children = []
    if dr.intake.present?
      children << intake_structure(dr.intake)
    end

    epes = dr.try(:end_product_establishments)&.to_a
    other_ris = dr.request_issues.where(end_product_establishment: nil).map { |ri| intake_structure(ri) }
    if epes.present?
      children << epes.map { |epe| intake_structure(epe) }
      children << { "other issues:": other_ris } if other_ris.present?
    else
      children << other_ris
    end

    children << dr.request_issues_updates.map { |riu| intake_structure(riu) }

    children.flatten
  end

  def decision_review_context(dr)
    dr.veteran
  end

  def intake_label(intake)
    "Intake #{intake.id}"
  end

  def intake_children(intake)
    ["performed by: #{user_label(intake.user)}"]
  end

  def intake_context(intake)
    intake.detail
  end

  def end_product_establishment_label(epe)
    attrs = [
      epe.code,
      "mod: #{epe.modifier}",
      epe.synced_status,
    ].compact.join(", ")
    "EndProductEstablishment #{epe.id} (#{attrs})"
  end

  def end_product_establishment_children(epe)
    epe.request_issues.map { |ri| intake_structure(ri) }
  end

  def end_product_establishment_context(epe)
    epe.source
  end

  def request_issue_label(ri)
    attrs = [ri.benefit_type]
    if ri.rating?
      attrs << "rating"
    elsif ri.nonrating?
      attrs << "nonrating"
    elsif ri.verified_unidentified_issue?
      attrs << "verified unidentified"
    else
      attrs << "unidentified"
    end
    attrs = attrs.compact.join(", ")
    "RequestIssue #{ri.id} (#{attrs})"
  end

  def request_issue_children(ri)
    children = []
    children << "edited: #{truncate(ri.edited_description, 50)}" if ri.edited_description.present?
    children << "#{ri.nonrating_issue_category} - #{ri.nonrating_issue_description}" if ri.nonrating?
    children << "Contention #{ri.contention_reference_id}" if ri.contention_reference_id
    children << "corrected by: #{request_issue_label(ri.correction_request_issue)}" if ri.corrected?
    if ri.ineligible_reason.present?
      label = "ineligible (#{ri.ineligible_reason})"
      if ri.ineligible_due_to_id.present?
        label += " due to #{request_issue_label(ri.ineligible_due_to)}"
      end
      children << label
    end
    history = request_issue_history(ri)
    children << { "history:": history } if history.present?
    children
  end

  def request_issue_history(ri)
    history = [
      [ri.closed_at, "closed: #{ri.closed_status}"],
      [ri.contention_removed_at, "contention removed"],
      [ri.contention_updated_at, "contention updated"],
      [ri.decision_sync_attempted_at, "decision sync attempted"],
      [ri.decision_sync_canceled_at, "decision sync canceled"]]
    history.select! { |hi| hi[0].present? }.map { |hi| "#{hi[0].to_s}: #{hi[1]}" }
  end

  def request_issue_context(ri)
    ri.end_product_establishment || ri.decision_review
  end

  def request_issues_update_children(riu)
    children = ["performed by: #{user_label(riu.user)}"]
    %w[ added removed withdrawn edited correction ].each do |update_type|
      issues = riu.send("#{update_type}_issues")
      if issues.present?
        children << { "#{update_type}:": issues.map { |ri| request_issue_label(ri) } }
      end
    end
    children
  end

  def request_issues_update_context(riu)
    riu.review
  end

  def user_label(user)
    "User #{user.id} (#{user.css_id})"
  end

  def truncate(text, size)
    text.size > size ? text[0, size - 1] + "…" : text
  end
end
