require "rails_helper"

RSpec.feature "Task queue" do
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

  before do
    FeatureToggle.enable!(:test_facols)

    User.authenticate!(user: attorney_user)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "attorney user with assigned tasks" do
    before { visit "/queue" }

    it "displays a table with a row for each case assigned to the attorney" do
      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)
    end

    it "supports custom sorting" do
      docket_number_column_header = page.find(:xpath, "//thead/tr/th[3]/span")
      docket_number_column_header.click
      docket_number_column_vals = page.find_all(:xpath, "//tbody/tr/td[3]")
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
      docket_number_column_header.click
      expect(docket_number_column_vals.map(&:text)).to eq vacols_tasks.map(&:docket_number).sort.reverse
    end

    it "displays special text indicating an assigned case has paper documents" do
      expect(page).to have_content("#{paper_appeal.veteran_full_name} (#{paper_appeal.vbms_id.delete('S')})")
      expect(page).to have_content(COPY::IS_PAPER_CASE)
    end
  end
end
