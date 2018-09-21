require "rails_helper"

RSpec.feature "Task queue" do
  before { FeatureToggle.enable!(:test_facols) }
  after { FeatureToggle.disable!(:test_facols) }

  let(:attorney_user) { FactoryBot.create(:user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let!(:simple_appeal) do
    FactoryBot.create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: FactoryBot.create(:case, :assigned, user: attorney_user)
    )
  end

  let!(:non_veteran_claimant_appeal) do
    FactoryBot.create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: FactoryBot.create(
        :case,
        :assigned,
        user: attorney_user,
        correspondent: FactoryBot.create(
          :correspondent,
          appellant_first_name: "Not",
          appellant_middle_initial: "D",
          appellant_last_name: "Veteran"
        )
      )
    )
  end

  let!(:paper_appeal) do
    FactoryBot.create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: FactoryBot.create(
        :case,
        :assigned,
        user: attorney_user,
        folder: FactoryBot.build(:folder, :paper_case)
      )
    )
  end

  let(:vacols_tasks) { QueueRepository.tasks_for_user(attorney_user.css_id) }

  context "attorney user with assigned tasks" do
    before do
      User.authenticate!(user: attorney_user)
      visit "/queue"
    end

    it "displays a table with a row for each case assigned to the attorney" do
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)
    end

    it "supports custom sorting" do
      docket_number_column_header = page.find(:xpath, "//thead/tr/th[3]/span/span[1]")
      docket_number_column_header.click
      docket_number_column_vals = page.find_all(:xpath, "//tbody/tr/td[3]/span[3]")
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
      docket_number_column_header.click
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
    end

    it "displays special text indicating an assigned case has paper documents" do
      expect(page).to have_content("#{paper_appeal.veteran_full_name} (#{paper_appeal.vbms_id.delete('S')})")
      expect(page).to have_content(COPY::IS_PAPER_CASE)
    end
  end

  context "VSO employee" do
    let(:vso) do
      v = FactoryBot.create(:vso)
      Vso.find(v.id)
    end
    let(:vso_employee) { FactoryBot.create(:user, :vso_role) }
    let!(:vso_task) { FactoryBot.create(:ama_vso_task, :in_progress, assigned_to: vso) }
    before do
      FeatureToggle.enable!(vso.feature.to_sym, users: [vso_employee.css_id])
      User.authenticate!(user: vso_employee)
      allow_any_instance_of(Vso).to receive(:user_has_access?).and_return(true)
      visit "/queue"
    end

    it "should be able to take actions on task from VSO queue" do
      # Redirect to VSO-specific URL
      expect(page.current_path).to eq(vso.path)

      case_details_link = page.find(:xpath, "//tbody/tr/td[1]/a")
      case_details_link.click
      expect(page).to have_content(COPY::CASE_SNAPSHOT_ACTION_BOX_TITLE)

      # Marking the task as complete correctly changes the task's status in the database.
      find(".Select-control", text: "Select an action…").click
      find("div", class: "Select-option", text: "Mark task complete").click

      find("button", id: "button-next-button", text: "Mark complete").click

      expect(page).to have_content(COPY::TASK_MARKED_COMPLETE_NOTICE_TITLE)
      expect(Task.find(vso_task.id).status).to eq("completed")
    end
  end
end
