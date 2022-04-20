# frozen_string_literal: true

class PreDocketTasksFactory
  def initialize(appeal)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)

    if vha_has_issues?
      call_vha
    elsif edu_predocket_needed?
      call_edu
    end
  end

  def edu_predocket_needed?
    @appeal.request_issues.active.any? { |ri| ri.benefit_type == "education" }
  end

  def vha_has_issues?
    @appeal.request_issues.active.any? { |ri| ri.benefit_type == "vha" }
  end

  def call_vha
    pre_docket_task = PreDocketTask.create!(
      appeal: @appeal,
      assigned_to: BvaIntake.singleton,
      parent: @root_task
    )
    VhaDocumentSearchTask.create!(
      appeal: @appeal,
      assigned_by: @appeal.intake.user,
      assigned_to: VhaCamo.singleton,
      parent: pre_docket_task
    )
  end

  def call_edu
    pre_docket_task = PreDocketTask.create!(
      appeal: @appeal,
      assigned_to: BvaIntake.singleton,
      parent: @root_task
    )
    EducationDocumentSearchTask.create!(
      appeal: @appeal,
      assigned_by: @appeal.intake.user,
      assigned_to: EducationEmo.singleton,
      parent: pre_docket_task
    )
  end
end
