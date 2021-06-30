# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_exporter.rb"
require "helpers/sanitized_json_importer.rb"
require "helpers/intake_renderer.rb"
require "helpers/hearing_renderer.rb"

RSpec.feature "Explain JSON" do
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
      started_at: 2.days.ago,
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
  scenario "admin visits explain page for intaken appeal" do
    # intake.complete!(params)

    visit "explain/appeals/#{appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{appeal.id})")
  end

  # 3 appeals are involved: `source_appeal` goes through CAVC remand to create `cavc_remand.remand_appeal`,
  # which goes through appellant substitution to create `appellant_substitution.target_appeal`.
  let(:source_appeal) { create(:appeal, :dispatched, :type_cavc_remand) }
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
  scenario "admin visits explain page for appellant_substitution CAVC-remanded appeal" do
    visit "explain/appeals/#{appellant_substitution.target_appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{appellant_substitution.target_appeal.id})")
    expect(page).to have_content("priority: true (AOD: false, CAVC: true)")

    visit "explain/appeals/#{appellant_substitution.source_appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{appellant_substitution.source_appeal.id})")
    expect(page).to have_content("priority: true (AOD: false, CAVC: true)")

    cavc_remand = appellant_substitution.source_appeal.cavc_remand
    visit "explain/appeals/#{cavc_remand.source_appeal.uuid}"
    expect(page).to have_content("Appeal.find(#{cavc_remand.source_appeal.id})")
    expect(page).to have_content("priority: false (AOD: false, CAVC: false)")
  end

  context "for a realistic appeal" do
    let(:real_appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/#{json_filename}", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end
    context "given a dispatched appeal" do
      let(:json_filename) { "appeal-21430.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}"
        expect(page).to have_content("show_pii = false")
        expect(page).to have_content("status: dispatched")

        expect(page).to have_content("priority: false (AOD: false, CAVC: false)")
        expect(page).to have_content("Intake (no PII)")
        expect(page).to have_content("Hearing (no PII)")
        expect(page).to have_content("show_pii: false")
        expect(page).to have_content("Appeal Narrative (contains PII)")

        click_link("toggle show_pii")
        expect(page).to have_content("show_pii = true")
        expect(page).to have_content("Intake (showing PII)")
        expect(page).to have_content("Hearing (showing PII)")
        expect(page).to have_content("show_pii: true")
        expect(page).to have_content("Appeal Narrative (contains PII)")
        page.find("#narrative_table").click
        task = real_appeal.tasks.sample
        expect(page).to have_content("#{task.type}_#{task.id}")
      end
    end

    context "given an AOD appeal" do
      let(:json_filename) { "appeal-121304-dup_jatasks.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}"
        expect(page).to have_content("status: distributed_to_judge")
        expect(page).to have_content("priority: true (AOD: true, CAVC: false)")
        # scroll_to(page.find("h3", text: "Timeline"))
        # binding.pry
      end
    end

    context "given an appeal dispatched before quality review is complete" do
      before do
        Organization.create!(id: 212, url: "bvajlmarch", name: "BVAJLMARCH")
      end
      let(:json_filename) { "appeal-dispatch_before_quality_review_complete.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}"
        expect(page).to have_content("status: assigned_to_colocated")
        expect(page).to have_content("priority: false (AOD: false, CAVC: false)")
      end
    end

    context "given an appeal with request issue contesting an HLR decision" do
      let(:json_filename) { "appeal-106435.json" }
      before do
        # 106435.json requires this HLR to exist because a decision_issue references it
        FactoryBot.create(:higher_level_review, id: 2_000_085_625)
      end
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}"
        page.find("#narrative_table").click
        req_issue = real_appeal.request_issues.sample
        expect(page).to have_content("#{req_issue.type}_#{req_issue.id}")
      end
    end
  end
end
