# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_exporter.rb"
require "helpers/intake_renderer.rb"

RSpec.feature "Export JSON" do
  let(:user_roles) { ["System Admin"] }
  before do
    User.authenticate!(roles: user_roles)
  end

  let(:veteran) { create(:veteran, file_number: "111447777", middle_name: "Middle") }
  let(:appeal) do
    create(:appeal,
           :advanced_on_docket_due_to_motion,
           :with_schedule_hearing_tasks,
           :with_post_intake_tasks,
           veteran: veteran)
  end
  let!(:intake) do
    AppealIntake.create(
      user: create(:user),
      detail: appeal,
      veteran_file_number: veteran.file_number,
      completed_at: 1.day.ago
    )
  end
  # let(:params) { { request_issues: issue_data } }
  # let(:issue_data) do
  #   [
  #     {
  #       rating_issue_reference_id: "reference-id",
  #       decision_text: "decision text"
  #     },
  #     { decision_text: "nonrating request issue decision text",
  #       nonrating_issue_category: "test issue category",
  #       benefit_type: "compensation",
  #       decision_date: "2018-12-25" }
  #   ]
  # end
  scenario "admin visits export page for intaken appeal" do
    # intake.complete!(params)

    visit "export/appeals/#{appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{appeal.id})")
  end

  # 3 appeals are involved: `source_appeal` goes through CAVC remand to create `cavc_remand.remand_appeal`,
  # which goes through appellant substitution to create `appellant_substitution.target_appeal`.
  let(:source_appeal) { create(:appeal, :dispatched, :type_cavc_remand, :advanced_on_docket_due_to_motion) }
  let(:created_by) { create(:user) }
  let(:substitute) { create(:claimant) }
  let(:poa_participant_id) { "13579" }
  let(:appellant_substitution) do
    AppellantSubstitution.create!(
      created_by: created_by,
      source_appeal: source_appeal,
      substitution_date: 5.days.ago.to_date,
      claimant_type: substitute&.type,
      substitute_participant_id: substitute&.participant_id,
      poa_participant_id: poa_participant_id
    )
  end

  before do
    attorney_task = source_appeal.tasks.of_type(:AttorneyTask).last
    create(:attorney_case_review, task: attorney_task, attorney: attorney_task.assigned_to)
    JudgeCaseReview.complete(
      location: "bva_dispatch",
      task_id: attorney_task.parent.id,
      judge: attorney_task.parent.assigned_to,
      attorney: attorney_task.assigned_to,
      complexity: "hard",
      quality: "meets_expectations",
      comment: "do this",
      factors_not_considered: %w[theory_contention relevant_records],
      areas_for_improvement: ["process_violations"],
      issues: [{ disposition: "allowed", description: "something1",
                 benefit_type: "compensation", diagnostic_code: "9999",
                 request_issue_ids: source_appeal.request_issues.ids }]
    )
  end
  scenario "admin visits export page for appellant_substitution CAVC-remanded appeal" do
    visit "export/appeals/#{appellant_substitution.target_appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{appellant_substitution.target_appeal.id})")
  end
end
