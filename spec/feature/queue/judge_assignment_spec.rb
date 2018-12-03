require "rails_helper"

RSpec.feature "Judge assignment to attorney" do
  # Note: these tests rely on the mapping in attorney_judge_teams.rb, the CSS IDs come from there.

  let(:judge) { create(:user, css_id: "BVABDANIEL", full_name: "Billie Daniel") }
  let(:attorney_one) { create(:user, css_id: "BVAMZEMLAK", full_name: "Moe Syzlak") }
  let(:attorney_two) { create(:user, css_id: "BVAAMACGYVER2", full_name: "Alice Macgyvertwo") }
  let(:appeal_one) { FactoryBot.create(:appeal) }
  let(:appeal_two) { FactoryBot.create(:appeal) }

  before do
    create(:staff, :judge_role, slogid: "TEST0", sdomainid: judge.css_id)
    create(:staff, :attorney_role, slogid: "TEST1", sdomainid: attorney_one.css_id)
    create(:staff, :attorney_role, slogid: "TEST2", sdomainid: attorney_two.css_id)
    create(:ama_judge_task, :in_progress, assigned_to: judge, appeal: appeal_one)
    create(:ama_judge_task, :in_progress, assigned_to: judge, appeal: appeal_two)
    User.authenticate!(user: judge)
  end

  context "Can move appeals between attorneys" do
    scenario "submits draft decision" do
      visit "/queue"
      click_on "Switch to Assign Cases"

      expect(page).to have_content("Cases to Assign (2)")
      expect(page).to have_content("Moe Syzlak")
      expect(page).to have_content("Alice Macgyvertwo")

      case_rows = page.find_all("tr[id^='table-row-']")
      expect(case_rows.length).to eq(2)

      case_rows.each do |row|
        # TODO: how do we check these checkboxes?

        # Approaches I tried:
        # row.find(".cf-form-checkbox").click -> does not seem to change the checkbox state.
        # row.find("input", visible: false).click -> fails since you're not allowed to click hidden elements
        # page.find("label[for=\"#{appeal_one.uuid}\"]").click -> fails with message:
        # Element is not clickable. Other element would receive the click:
        # <div class="cf-form-checkbox">...</div>
      end
    end
  end

  context "Can view their queue" do
    scenario "when viewing the review task queue" do
      judge_review_task = create(:ama_judge_review_task, :in_progress, assigned_to: judge)
      expect(judge_review_task.status).to eq("in_progress")
      appeal_review = judge_review_task.appeal
      vet = appeal_review.veteran
      attorney_completed_task = create(:ama_attorney_task, appeal: appeal_review, parent: judge_review_task)
      attorney_completed_task.mark_as_complete!
      case_review = create(:attorney_case_review, task_id: attorney_completed_task.id)

      visit "/queue"

      expect(page).to have_content("Review 1 Cases")
      expect(page).to have_content("#{vet.first_name} #{vet.last_name}")
      expect(page).to have_content(appeal_review.veteran_file_number)
      expect(page).to have_content(case_review.document_id)
      expect(page).to have_content("Original")
      expect(page).to have_content(appeal_review.docket_number)
    end

    scenario "when viewing the assign task queue" do
      judge_assign_task = create(:ama_judge_task, :in_progress, assigned_to: judge)
      appeal_assign = judge_assign_task.appeal
      vet = appeal_assign.veteran

      visit "/queue"

      click_on "Switch to Assign Cases"

      expect(page).to have_content("Assign 3 Cases")
      expect(page).to have_content("#{vet.first_name} #{vet.last_name}")
      expect(page).to have_content(appeal_assign.veteran_file_number)
      expect(page).to have_content("Original")
      expect(page).to have_content(appeal_assign.docket_number)
    end
  end
end
