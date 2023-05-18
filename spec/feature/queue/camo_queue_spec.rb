# frozen_string_literal: true

feature "CamoQueue", :all_dbs do
  context "Load CAMO Queue" do
    let(:organization) { VhaCamo.singleton }
    let(:camo_user) { User.authenticate!(roles: ["Admin Intake"]) }

    before do
      organization.add_user(camo_user)
      camo_user.reload
      visit "/organizations/#{organization.url}"
    end

    scenario "CAMO Queue Loads" do
      expect(find("h1")).to have_content("VHA CAMO cases")
    end

    context "ordering and filtering by the issue type column" do
      let!(:tasks) { create_list(:vha_document_search_task, 6) }
      let(:issue_types) do
        [
          "CHAMPVA",
          "Caregiver | Other",
          "Beneficiary Travel",
          "Prosthetics | Other (not clothing allowance)",
          "Beneficiary Travel",
          "Medical and Dental Care Reimbursement"
        ]
      end
      let!(:request_issues) do
        issue_types.map do |issue_type|
          issue = create_vha_issue(issue_type)
          issue.save
          issue
        end
      end
      let(:filter_column_label_text) { "Issue Type" }

      before do
        tasks.each_with_index do |task, index|
          task.appeal.request_issues << request_issues[index]
          task.save
          task.appeal.save
          task.reload
          organization.reload
        end
        # The issue types column needs the CachedAppealsTable to be updated to sort and filter
        UpdateCachedAppealsAttributesJob.perform_now
        # Visit the url again since the ordering after initialization can be weird
        visit "/organizations/#{organization.url}"
      end

      scenario "ordering by the issue type column in the assigned tab" do
        # Sort by issue type
        find("[aria-label='Sort by Issue Type']").click

        # Check order and it should be sorted in descending order
        table_rows = all("table tbody tr")
        table_rows.each_with_index do |row, index|
          expect(row).to have_text(issue_types.sort_by(&:upcase).reverse[index])
          issue_types.sort_by(&:upcase)
        end

        # Click the issue type sort again
        find("[aria-label='Sort by Issue Type']").click

        # Check order and it should be in ascending order
        table_rows = all("table tbody tr")
        table_rows.each_with_index do |row, index|
          expect(row).to have_text(issue_types.sort_by(&:upcase)[index])
        end
      end

      scenario "filtering by the issue type column in the assigned tab" do
        # Verify Prosthetics | Other is present on the page
        expect(page).to have_content("Prosthetics | Other (not clothing allowance)")

        # Click the issue type filter icon
        find("[aria-label='Filter by issue type']").click

        # Check that all filter counts are there in alphanumerically sorted order
        issue_types.sort_by(&:upcase).each do |issue_type|
          if issue_type == "Beneficiary Travel"
            expect(page).to have_content("#{issue_type} (2)")
          else
            expect(page).to have_content("#{issue_type} (1)")
          end
        end

        # Filter by Medical and Dental Care Reimbursement
        find("label", text: "Medical and Dental Care Reimbursement").click
        expect(page).to have_content("Filtering by: #{filter_column_label_text} (1)")
        expect(page).to have_content("Medical and Dental Care Reimbursement")
        expect(page).to_not have_content("Beneficiary Travel")
        expect(page).to_not have_content("Prosthetics | Other (not clothing allowance)")

        # Filter again by Beneficiary Travel
        # Need a *= matcher because the aria-label is appended with all the filtered types for some reason.
        find("[aria-label*='Filter by issue type']").click
        find("label", text: "Beneficiary Travel").click
        expect(page).to have_content("Filtering by: #{filter_column_label_text} (2)")
        expect(page).to have_content("Medical and Dental Care Reimbursement")
        expect(page).to have_content("Beneficiary Travel")
        expect(page).to_not have_content("Prosthetics | Other (not clothing allowance)")

        # Clear filter and check if all the data is there again
        find(".cf-clear-filters-link").click

        expect(page).to_not have_content("Filtering by: #{filter_column_label_text}")
        expect(page).to have_content("Prosthetics | Other (not clothing allowance)")
        expect(page).to have_content("Medical and Dental Care Reimbursement")
        expect(page).to have_content("Beneficiary Travel")
      end
    end
  end

  def create_vha_issue(issue_type)
    create(:request_issue,
           benefit_type: "vha",
           nonrating_issue_category: issue_type,
           nonrating_issue_description: "VHA - Category")
  end
end
