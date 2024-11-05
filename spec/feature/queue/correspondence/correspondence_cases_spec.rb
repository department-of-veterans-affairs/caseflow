# frozen_string_literal: true

RSpec.feature("The Correspondence Cases page") do
  include CorrespondenceTaskHelpers
  # alias this to avoid the method name collision
  alias_method :create_efolderupload_task, :create_efolderupload_failed_task

  let(:current_user) { create(:user) }
  let(:current_super) { create(:inbound_ops_team_supervisor) }
  let(:veteran) { create(:veteran) }

  # Feature Toggle Tests
  describe "correspondece cases feature toggle" do
    before :each do
      correspondence_spec_user_access
      @correspondence_uuid = "123456789"
    end

    it "routes user to /under_construction if the feature toggle is disabled" do
      FeatureToggle.disable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(page).to have_current_path("/under_construction")
    end

    it "routes to correspondence cases if feature toggle is enabled" do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence"
      expect(current_path.include?("/queue/correspondence")).to eq true
    end
  end

  # Correspondence Cases Tests
  context "Correspondence Cases - Unassigned" do
    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
    end

    before do
      10.times do
        create(
          :correspondence,
          :with_single_doc,
          veteran_id: veteran.id,
          uuid: SecureRandom.uuid,
          va_date_of_receipt: Time.zone.local(2023, 1, 1)
        )
      end
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { |index| create(:correspondence, nod: index == 1) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            instructions: ["Default"],
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
    end

    it "successfully tests the unassigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence owned by the Mail team are unassigned to an individual:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Assign")
      expect(page).to have_button("Auto assign correspondence")
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Notes")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "correctly sorts Package Document Type" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Package Document Type']").click
      first_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      second_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task.text)
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task.text)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "correctly filters Package Document Type" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by Package Document Type']").click
      all(".cf-filter-option-row")[1].click
      expect(page).to_not have_content("Non-NOD")
    end

    it "correctly filters Package Document Type by selecting both options" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by Package Document Type']").click
      all(".cf-filter-option-row")[1].click
      find("[aria-label='Filter by Package Document Type. Filtering by true']").click
      all(".cf-filter-option-row")[2].click
      expect(page).to have_content("Package Document Type (2)")
      expect(page).to have_content("Viewing 1-15 of 30 total")
    end

    it "uses receipt date between filter correctly" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-2").click
      current_date = Time.zone.today
      my_date = (current_date - 5).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-3-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      click_button("Apply Filter")
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    # Search Bar Test
    it "correctly uses search bar" do
      visit "queue/correspondence/team?tab=correspondence_unassigned&page=1&sort_by=vaDor&order=asc"
      fill_in "searchBar", with: "-nod"
      expect all("td", text: "Non-NOD").length == 5
    end
  end

  context "Correspondence Cases - Action Required" do
    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end

      # Used to mock a single task to compare task sorting
      ReassignPackageTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      ReassignPackageTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
    end

    it "successfully tests the action required tab" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      expect(page).to have_content("Correspondence with pending requests:")
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Assigned By")
      expect(page).to have_content("Action Type")
      expect(page).to have_content("Notes")
    end

    it "uses assigned by sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Assigned By']").click
      first_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Assigned By']").click
      last_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare details
      find("[aria-label='Sort by Assigned By']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_assignee)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Assigned By']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_assignee)
    end

    it "uses action type sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_action_required"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Action Type']").click
      first_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Action Type']").click
      second_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Action Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task_type)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Action Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task_type)
    end
  end

  context "Correspondence Cases - Pending" do
    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      5.times do
        corres_array = (1..4).map { create(:correspondence) }
        task_array = [CavcCorrespondenceCorrespondenceTask,
                      CongressionalInterestCorrespondenceTask,
                      DeathCertificateCorrespondenceTask,
                      PrivacyActRequestCorrespondenceTask]

        corres_array.each_with_index do |corres, index|
          task_array[index].create!(
            appeal_id: corres.id,
            appeal_type: "Correspondence",
            assigned_to: InboundOpsTeam.singleton
          )
        end
      end

      # Used to mock a single task to compare task sorting
      PrivacyActRequestCorrespondenceTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      PrivacyActRequestCorrespondenceTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
    end

    it "successfully tests the pending tab" do
      visit "/queue/correspondence/team?tab=correspondence_pending&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence that is currently assigned to non-mail team users:")
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Tasks")
      expect(page).to have_content("Assigned To")
    end

    it "uses tasks sort correctly." do
      visit "/queue/correspondence/team?tab=correspondence_pending&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Tasks']").click
      first_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Tasks']").click
      second_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task_type)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task_type)
    end

    it "uses uses task filter correctly" do
      visit "/queue/correspondence/team?tab=correspondence_pending&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find("label", text: "Death Certificate Correspondence Task (5)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 5)
    end
  end

  context "Correspondence Cases - Pending Tasks - part 2" do
    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    # Creating correspondence with each task type
    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))

      task_array = [
        PrivacyComplaintCorrespondenceTask,
        CongressionalInterestCorrespondenceTask,
        StatusInquiryCorrespondenceTask,
        PowerOfAttorneyRelatedCorrespondenceTask,
        PrivacyActRequestCorrespondenceTask,
        DeathCertificateCorrespondenceTask,
        OtherMotionCorrespondenceTask,
        CavcCorrespondenceCorrespondenceTask
      ]

      3.times do
        corres_array = (1..8).map { create(:correspondence, :pending) }

        corres_array.each do |corres|
          task_array.each do |task|
            next if corres.tasks.any? { |e| e.instance_of? task }

            task.create!(
              appeal_id: corres.id,
              appeal_type: "Correspondence",
              assigned_to: InboundOpsTeam.singleton
            )
          end
        end
      end
    end

    it "verifies routes for PrivacyComplaintCorrespondenceTask types on the pending tab." do
      # filter PrivacyComplaintCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Privacy Complaint Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for CongressionalInterestCorrespondenceTask types on the pending tab." do
      # filter CongressionalInterestCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Congressional Interest Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for StatusInquiryCorrespondenceTask types on the pending tab." do
      # filter StatusInquiryCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Status Inquiry Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for PowerOfAttorneyRelatedCorrespondenceTask types on the pending tab." do
      # filter PowerOfAttorneyRelatedCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Power Of Attorney Related Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for PrivacyActRequestCorrespondenceTask types on the pending tab." do
      # filter PrivacyActRequestCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Privacy Act Request Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for DeathCertificateCorrespondenceTask types on the pending tab." do
      # filter DeathCertificateCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Death Certificate Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for OtherMotionCorrespondenceTask types on the pending tab." do
      # filter OtherMotionCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Other Motion Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end

    it "verifies routes for CavcCorrespondenceCorrespondenceTask types on the pending tab." do
      # filter CavcCorrespondenceCorrespondenceTask on pending tab & verify link to Correspondence Details
      visit "/queue/correspondence/team?tab=correspondence_pending"
      all(".unselected-filter-icon")[2].click
      find("label", text: /Cavc Correspondence Correspondence Task/).click
      all("a", id: "task-link")[0].click
      expect(page).to have_content(/.*Record status:.*Pending.*/)
    end
  end

  context "Correspondence Cases - Assigned" do
    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_super, status: "assigned")
        rpt.save!
      end
      10.times do
        corr = create(:correspondence)

        rpt = ReviewPackageTask.find_by(appeal_id: corr.id)

        EfolderUploadFailedTask.create!(
          parent_id: rpt.id,
          appeal_id: corr.id,
          appeal_type: "Correspondence",
          assigned_to: current_super,
          assigned_by_id: rpt.assigned_to_id
        )
      end

      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2050, 10, 10)
      )
      FeatureToggle.enable!(:correspondence_queue)
    end

    it "successfully tests the assigned tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence that is currently assigned to mail team users:")
      expect(page).to have_content("Assign to Inbound Ops Team user")
      expect(page).to have_button("Reassign", disabled: true)
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Tasks")
      expect(page).to have_content("Assigned To")
      expect(page).to have_content("Notes")
    end

    it "uses assigned to sort correctly" do
      visit "/queue/correspondence/team?tab=correspondence_team_assigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Assigned To']").click
      first_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Assigned To']").click
      last_assignee = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare details
      find("[aria-label='Sort by Assigned To']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_assignee)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Assigned To']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_assignee)
    end
  end

  context "Correspondence Cases - Completed" do
    let(:current_super) { create(:correspondence_auto_assignable_user, :super_user) }

    before :each do
      correspondence_spec_super_access
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence_uuid = "123456789"
    end

    before do
      20.times do
        correspondence_root_task_completion
      end
    end

    it "successfully tests the completed tab" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Date Completed")
      expect(page).to have_content("Notes")
      expect(page).to have_content("Completed correspondence:")
      expect(page).to have_content("Viewing 1-15 of 20 total")
      expect(page).to have_button("Next")
      expect(page).not_to have_button("Previous")

      click_button("Next", match: :first)
      expect(page).to have_content("Viewing 16-20 of 20 total")
      expect(page).to have_button("Previous")
      expect(page).not_to have_button("Next")

      click_button("Previous", match: :first)
      expect(page).to have_content("Viewing 1-15 of 20 total")
    end

    it "displays all correspondence tasks sorted by date completed" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Date Completed']").click

      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort.reverse)

      find("[aria-label='Sort by Date Completed']").click
      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort)
    end

    it "filters date column with 'between' the dates" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-0").click
      current_date = Time.zone.today
      start_date = (current_date - 1).strftime("%m/%d/%Y")
      end_date = current_date.strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      all("div.input-container > input")[1].fill_in(with: end_date)

      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'before' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-1").click
      current_date = Time.zone.today
      start_date = (current_date - 3).strftime("%m/%d/%Y")

      all("div.input-container > input")[0].fill_in(with: start_date)
      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'after' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-2").click
      current_date = Time.zone.yesterday
      after_date = (current_date + 1).strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: after_date)
      expect(page).to have_button("Apply filter", disabled: false)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end

    it "filters date column with 'on' this date" do
      visit "/queue/correspondence/team?tab=correspondence_team_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by date completed']").click
      expect(page).to have_content("Date filter parameters")
      expect(page).to have_button("Apply filter", disabled: true)

      find("#reactSelectContainer").click
      find("#react-select-2-option-3").click
      current_date = Time.zone.today
      on_this_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: on_this_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(3)").length).to eq(1)
    end
  end

  context "Your Correspondence Assigned Tab" do
    before :each do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "assigned")
        rpt.save!
      end

      corres_array = (1..4).map { |index| create(:correspondence, nod: index == 1) }
      task_array = [ReassignPackageTask, RemovePackageTask, SplitPackageTask, MergePackageTask]

      corres_array.each_with_index do |corres, index|
        rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
        task_array[index].create!(
          parent_id: rpt.id,
          appeal_type: "Correspondence",
          appeal_id: corres.id,
          assigned_to: InboundOpsTeam.singleton,
          status: "assigned",
          instructions: ["Default"],
          assigned_by_id: 1
        )
        rpt.update!(assigned_to: current_user, status: "assigned")
        rpt.save!
      end
    end

    it "successfully tests the assigned tab" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Notes")
    end

    it "uses veteran details sort correctly." do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Veteran Details']").click
      first_vet_info = page.all("#task-link")[0].text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Veteran Details']").click
      last_vet_info = page.all("#task-link")[0].text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == first_vet_info)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Veteran Details']").click
      expect(page.all("#task-link")[0].text == last_vet_info)
    end

    it "correctly sorts Package Document Type" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Package Document Type']").click
      first_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      second_task = find("tbody > tr:nth-child(1) > td:nth-child(3)")
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task.text)
      find("[aria-label='Package Document Type']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task.text)
    end

    it "uses VA DOR sort correctly." do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by VA DOR']").click
      first_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # put page in the sorted Z-A state
      find("[aria-label='Sort by VA DOR']").click
      last_date = find("tbody > tr:nth-child(1) > td:nth-child(2)")
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == first_date)
      # return to Z-A, compare details again
      find("[aria-label='Sort by VA DOR']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(2)").text == last_date)
    end

    it "uses days waiting sort correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Days Waiting']").click
      first_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Days Waiting']").click
      second_day_amount = find("tbody > tr:nth-child(1) > td:nth-child(4)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == first_day_amount)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Days Waiting']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(4)").text == second_day_amount)
    end

    it "uses notes sort correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Notes']").click
      first_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Notes']").click
      second_note = find("tbody > tr:nth-child(1) > td:nth-child(5)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == first_note)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Notes']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(5)").text == second_note)
    end

    it "correctly filters Package Document Type" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by Package Document Type']").click
      all(".cf-filter-option-row")[1].click
      expect(page).to_not have_content("Non-NOD")
    end

    it "correctly filters Package Document Type by selecting both options" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Filter by Package Document Type']").click
      all(".cf-filter-option-row")[1].click
      find("[aria-label='Filter by Package Document Type. Filtering by true']").click
      all(".cf-filter-option-row")[2].click
      expect(page).to have_content("Package Document Type (2)")
      expect(page).to have_content("Viewing 1-14 of 14 total")
    end

    it "uses receipt date between filter correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date before filter correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date after filter correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "uses receipt date on filter correctly" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[1].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    # Search Bar Test
    it "correctly uses search bar" do
      visit "/queue/correspondence?tab=correspondence_assigned&page=1&sort_by=vaDor&order=asc"
      fill_in "searchBar", with: "-nod"
      expect all("td", text: "Non-NOD").length == 5
    end
  end

  context "Your Correspondence In-Progress Tab" do
    before :each do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      20.times do
        correspondence = create(:correspondence)
        parent_task = create_correspondence_intake(correspondence, current_user)
        create_efolderupload_task(correspondence, parent_task)
      end
      # Used to mock a single task to compare task sorting
      EfolderUploadFailedTask.first.update!(type: "ReviewPackageTask")
      EfolderUploadFailedTask.first.correspondence.update!(
        va_date_of_receipt: Date.new(2000, 10, 10)
      )
      EfolderUploadFailedTask.last.correspondence.update!(
        va_date_of_receipt: Date.new(2024, 10, 10)
      )
    end

    it "successfully tests the in progress tab" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Correspondence in progress")
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Tasks")
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Notes")
    end

    it "uses tasks sort correctly." do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      # put page in the sorted A-Z state
      find("[aria-label='Sort by Tasks']").click
      first_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # put page in the sorted Z-A state
      find("[aria-label='Sort by Tasks']").click
      second_task_type = find("tbody > tr:nth-child(1) > td:nth-child(3)").text
      # return to A-Z, compare veteran details
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == first_task_type)
      # return to Z-A, compare details again
      find("[aria-label='Sort by Tasks']").click
      expect(find("tbody > tr:nth-child(1) > td:nth-child(3)").text == second_task_type)
    end

    it "uses uses task filter correctly" do
      visit "/queue/correspondence?tab=correspondence_in_progress&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find("label", text: "Review Package Task (1)").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(4)").length == 1)
    end
  end

  context "Your Correspondence Completed Tab" do
    before :each do
      correspondence_spec_user_access
      FeatureToggle.enable!(:correspondence_queue)
    end

    before do
      Timecop.freeze(Time.zone.local(2020, 5, 15))
      10.times do
        review_correspondence = create(:correspondence)
        rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
        rpt.update!(assigned_to: current_user, status: "completed")
        rpt.save!
      end
      review_correspondence = create(:correspondence)
      rpt = ReviewPackageTask.find_by(appeal_id: review_correspondence.id)
      rpt.update!(assigned_to: current_user, status: "completed", closed_at: Date.new(2000, 10, 10))
      rpt.save!
    end

    it "successfully tests the completed tab" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      expect(page).to have_content("Completed correspondence")
      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("Package Document Type")
      expect(page).to have_content("VA DOR")
      expect(page).to have_content("Date Completed")
      expect(page).to have_content("Notes")
    end

    it "displays all correspondence tasks sorted by date completed" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Date Completed']").click

      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort.reverse)

      find("[aria-label='Sort by Date Completed']").click
      dates = all("tbody > tr > td:nth-child(3)").map(&:text)
      expect(dates).to eq(dates.sort)
    end

    it "filters date column with 'between' the dates" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-0").click
      all("div.input-container > input")[0].fill_in(with: "10/09/2000")
      all("div.input-container > input")[1].fill_in(with: "10/11/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "filters date column with 'before' this date" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-1").click
      all("div.input-container > input")[0].fill_in(with: "10/01/2001")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "filters date column with 'after' this date" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-2").click
      current_date = Time.zone.today
      my_date = current_date.strftime("%m/%d/%Y")
      all("div.input-container > input")[0].fill_in(with: my_date)
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end

    it "filters date column with 'on' this date" do
      visit "/queue/correspondence?tab=correspondence_completed&page=1&sort_by=vaDor&order=asc"
      all(".unselected-filter-icon")[2].click
      find_by_id("reactSelectContainer").click
      find_by_id("react-select-2-option-3").click
      all("div.input-container > input")[0].fill_in(with: "10/10/2000")
      find(".cf-submit").click
      expect(all("tbody > tr:nth-child(1) > td:nth-child(5)").length == 1)
    end
  end

  context "Banner alert for approval and reject request" do
    let(:banner_user) { create(:correspondence_auto_assignable_user, :super_user) }

    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(user: banner_user)
    end

    before do
      5.times do
        create(:correspondence_auto_assignable_user)
        corres_array = (1..2).map { create(:correspondence) }
        task_array = [ReassignPackageTask, RemovePackageTask]

        corres_array.each_with_index do |corres, index|
          rpt = ReviewPackageTask.find_by(appeal_id: corres.id)
          task_array[index].create!(
            parent_id: rpt.id,
            appeal_type: "Correspondence",
            appeal_id: corres.id,
            assigned_to: InboundOpsTeam.singleton,
            instructions: ["This was the default"],
            assigned_by_id: rpt.assigned_to_id
          )
        end
      end
    end

    it "approve request to reassign" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find('[for="vertical-radio_approve"]').click
      find("#react-select-2-input").find(:xpath, "..").find(:xpath, "..").find(:xpath, "..").click
      find("#react-select-2-option-0").click
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully reassigned a mail record for")
      end
    end

    it "deny request to reassign" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find('[for="vertical-radio_reject"]').click
      all("textarea")[0].fill_in with: "this is a rejection reason"
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request for")
      end
    end

    it "approve request to reassign in review_package view" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("#Review-request-button-id-2").click
      find("#button-Review-reassign-request").click
      find('[for="reassign-package_approve"]').click
      find("#react-select-4-input").find(:xpath, "..").find(:xpath, "..").find(:xpath, "..").click
      find("#react-select-4-option-0").click
      click_button("Confirm")
      using_wait_time(30) do
        expect(page).to have_content("You have successfully reassigned a mail record for")
      end
    end

    it "deny request to reassign in review_package view" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("#Review-request-button-id-2").click
      find("#button-Review-reassign-request").click
      find('[for="reassign-package_reject"]').click
      find(".cf-form-textarea", match: :first).fill_in with: "this is a rejection reason"
      click_button("Confirm")
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request")
      end
    end

    it "approve request to remove" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      find("[aria-label='Sort by Action Type']").click
      all("tr")[2].find("a#task-link").click
      find('[for="vertical-radio_approve"]').click
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully removed a mail package for")
      end
    end

    it "deny request to remove" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[2].find("a#task-link").click
      find('[for="vertical-radio_reject"]').click
      all("textarea")[0].fill_in with: "this is a rejection reason"
      find("#Review-request-button-id-1").click
      using_wait_time(30) do
        expect(page).to have_content("You have successfully rejected a package request")
      end
    end

    it "goes to Task Package" do
      visit "queue/correspondence/team?tab=correspondence_action_required&page=1&sort_by=vaDor&order=asc"
      all("tr")[1].find("a#task-link").click
      find("[id='Review-request-button-id-2']").click
      expect(page).to have_content("Review the mail package details below.")
    end
  end
end
