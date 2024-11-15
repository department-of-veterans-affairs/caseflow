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

  context "given Legacy appeal" do
    let(:legacy_appeal) do
      create(:legacy_appeal, :with_veteran,
             :with_schedule_hearing_tasks,
             :with_judge_assign_task,
             vacols_case: create(:case, :aod))
    end
    scenario "admin visits explain page for legacy appeal" do
      visit "explain/appeals/#{legacy_appeal.vacols_id}?sections=all"
      expect(page).to have_content("priority: true (AOD: true, CAVC: false)")
      expect(page).to have_content("Unscheduled Hearing (SCH Task ID: ")

      expect(page).to have_content("NOD received")

      # Access page using record id
      visit "explain/appeals/legacy-#{legacy_appeal.id}?sections=all"
      expect(page).to have_content("priority: true (AOD: true, CAVC: false)")
    end
  end

  context "given AMA appeal" do
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

      visit "explain/appeals/#{appeal.uuid}?sections=all"
      expect(page).to have_content("Appeal.find(#{appeal.id})")

      # Access page using record id
      visit "explain/appeals/ama-#{appeal.id}?sections=all"
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
      visit "explain/appeals/#{appellant_substitution.target_appeal.uuid}?sections=all"
      expect(page).to have_content(appellant_substitution.target_appeal.id)
      expect(page).to have_content("priority: true (AOD: false, CAVC: true)")

      visit "explain/appeals/#{appellant_substitution.source_appeal.uuid}?sections=all"
      expect(page).to have_content(appellant_substitution.source_appeal.id)
      expect(page).to have_content("priority: true (AOD: false, CAVC: true)")

      cavc_remand = appellant_substitution.source_appeal.cavc_remand
      visit "explain/appeals/#{cavc_remand.source_appeal.uuid}?sections=all"
      expect(page).to have_content(cavc_remand.source_appeal.id)
      expect(page).to have_content("priority: false (AOD: false, CAVC: false)")
    end
  end

  context "for a realistic appeal" do
    let(:real_appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/#{json_filename}", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end
    context "given a dispatched appeal" do
      before do
        real_appeal.root_task.tap do |task|
          task.append_instruction "Adding instruction on RootTask"
          task.append_instruction "Adding instruction to show task versions"
        end
        real_appeal.tasks.sample.tap do |task|
          task.append_instruction "Adding instruction"
          task.append_instruction "Adding instruction to show task versions"
        end
      end
      let(:json_filename) { "appeal-21430.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}?sections=all"
        expect(page).to have_content("show_pii = false")
        expect(page).to have_content("status: dispatched")

        expect(page).to have_content("priority: false (AOD: false, CAVC: false)")
        expect(page).to have_content("Intake (no PII)")
        expect(page).to have_content("Hearing (no PII)")
        expect(page).to have_content("Appeal Narrative (showing PII)")
        expect(page).to have_content("Timeline visualization")

        expect(page).to have_content("task.version_summary")
        find(id: "#{real_appeal.root_task.id}_versions").click
        expect(page).to have_content("Adding instruction to show task versions")

        click_link("toggle show_pii")
        expect(page).to have_content("show_pii = true")
        expect(page).to have_content("Intake (showing PII)")
        expect(page).to have_content("Hearing (showing PII)")
        expect(page).to have_content("Appeal Narrative (showing PII)")
        task = real_appeal.tasks.sample
        expect(page).to have_content("#{task.type}_#{task.id}")
      end
    end

    context "given an AOD appeal" do
      let(:json_filename) { "appeal-121304-dup_jatasks.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}?sections=all"
        expect(page).to have_content("status: distributed_to_judge")
        expect(page).to have_content("priority: true (AOD: true, CAVC: false)")
        expect(page).to have_content("Timeline visualization")
      end
    end

    context "given an appeal dispatched before quality review is complete" do
      before do
        Organization.create!(id: 212, url: "bvajlmarch", name: "BVAJLMARCH")
      end
      let(:json_filename) { "appeal-dispatch_before_quality_review_complete.json" }
      it "present realistic appeal events" do
        visit "explain/appeals/#{real_appeal.uuid}?sections=all"
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
        visit "explain/appeals/#{real_appeal.uuid}?sections=all"
        req_issue = real_appeal.request_issues.sample
        expect(page).to have_content("#{req_issue.type}_#{req_issue.id}")
      end
    end
  end

  context "for appeals with affinity dates" do
    let!(:legacy_appeal_with_affinity) do
      vacols_case = create(:case_with_form_9, :with_appeal_affinity, :ready_for_distribution)
      create(:legacy_appeal, vacols_case: vacols_case)
      vacols_case
    end
    let!(:legacy_appeal_without_affinity) do
      vacols_case = create(:case_with_form_9, :ready_for_distribution)
      create(:legacy_appeal, vacols_case: vacols_case)
      vacols_case
    end
    let!(:ama_appeal_with_affinity) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute, :with_appeal_affinity,
             tied_judge: create(:user, :judge, :with_vacols_judge_record))
    end
    let!(:ama_appeal_without_affinity) do
      create(:appeal, :hearing_docket, :held_hearing_and_ready_to_distribute,
             tied_judge: create(:user, :judge, :with_vacols_judge_record))
    end

    it "legacy appeals show the date if one exists" do
      visit "explain/appeals/#{legacy_appeal_with_affinity.bfkey}"
      page.find("label", text: "Task Tree").click
      expect(page)
        .to have_text "Affinity Start Date: #{legacy_appeal_with_affinity.appeal_affinity.affinity_start_date}"

      visit "explain/appeals/#{legacy_appeal_without_affinity.bfkey}"
      page.find("label", text: "Task Tree").click
      expect(page)
        .not_to have_text "Affinity Start Date:"
    end

    it "AMA appeals show the date if one exists" do
      visit "explain/appeals/#{ama_appeal_with_affinity.uuid}"
      page.find("label", text: "Task Tree").click
      expect(page)
        .to have_text "Affinity Start Date: #{ama_appeal_with_affinity.reload.appeal_affinity.affinity_start_date}"

      visit "explain/appeals/#{ama_appeal_without_affinity.uuid}"
      page.find("label", text: "Task Tree").click
      expect(page)
        .not_to have_text "Affinity Start Date:"
    end
  end
end
