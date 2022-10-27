# frozen_string_literal: true

class PreDocketTasksFactory
  def initialize(appeal)
    @appeal = appeal
    @root_task = RootTask.find_or_create_by!(appeal: appeal)

    @pre_docket_task = PreDocketTask.create!(
      appeal: @appeal,
      assigned_to: BvaIntake.singleton,
      assigned_by: @appeal.intake.user,
      parent: @root_task
    )
  end

  def call_vha
    VhaDocumentSearchTask.create!(
      appeal: @appeal,
      assigned_by: @appeal.intake.user,
      assigned_to: determine_vha_assignee,
      parent: @pre_docket_task
    )
  end

  def call_edu
    EducationDocumentSearchTask.create!(
      appeal: @appeal,
      assigned_by: @appeal.intake.user,
      assigned_to: EducationEmo.singleton,
      parent: @pre_docket_task
    )
  end

  private

  def determine_vha_assignee
    return VhaCaregiverSupport.singleton if @appeal.caregiver_has_issues?

    VhaCamo.singleton
  end
end
