# frozen_string_literal: true

feature "NonComp Reviews Queue", :postgres do
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:user) { create(:default_user) }

  let(:veteran_a) { create(:veteran, first_name: "Aaa", participant_id: "12345", ssn: "140261454") }
  let(:veteran_b) { create(:veteran, first_name: "Bbb", participant_id: "601111772", ssn: "191097395") }
  let(:veteran_c) { create(:veteran, first_name: "Ccc", participant_id: "1002345", ssn: "128455943") }
  let(:hlr_a) { create(:higher_level_review, veteran_file_number: veteran_a.file_number) }
  let(:hlr_b) { create(:higher_level_review, veteran_file_number: veteran_b.file_number) }
  let(:hlr_c) { create(:higher_level_review, veteran_file_number: veteran_c.file_number) }
  let(:appeal) { create(:appeal, veteran: veteran_c) }

  let!(:request_issue_a) { create(:request_issue, :rating, decision_review: hlr_a) }
  let!(:request_issue_aa) { create(:request_issue, :rating, decision_review: hlr_a) }
  let!(:request_issue_b) { create(:request_issue, :rating, decision_review: hlr_b) }
  let!(:request_issue_c) { create(:request_issue, :rating, :removed, decision_review: hlr_c) }
  let!(:request_issue_d) { create(:request_issue, :rating, decision_review: appeal, closed_at: 1.day.ago) }

  let(:today) { Time.zone.now }
  let(:last_week) { Time.zone.now - 7.days }

  BASE_URL = "/decision_reviews/nco"

  let!(:completed_tasks) do
    [
      create(:higher_level_review_task,
             :completed,
             appeal: hlr_a,
             assigned_to: non_comp_org,
             closed_at: last_week),
      create(:higher_level_review_task,
             :completed,
             appeal: hlr_b,
             assigned_to: non_comp_org,
             closed_at: today),
      create(:higher_level_review_task,
             :completed,
             appeal: hlr_c,
             assigned_to: non_comp_org,
             closed_at: 2.days.ago)
    ]
  end

  let!(:in_progress_tasks) do
    [
      create(:higher_level_review_task,
             :in_progress,
             appeal: hlr_a,
             assigned_to: non_comp_org,
             assigned_at: last_week),
      create(:higher_level_review_task,
             :in_progress,
             appeal: hlr_b,
             assigned_to: non_comp_org,
             assigned_at: today),
      create(:higher_level_review_task,
             :in_progress,
             appeal: hlr_c,
             assigned_to: non_comp_org,
             assigned_at: today),
      create(:board_grant_effectuation_task,
             :in_progress,
             appeal: appeal,
             assigned_to: non_comp_org,
             assigned_at: 1.day.ago)
    ]
  end

  let(:search_box_label) { "Search by Claimant Name, Veteran Participant ID, File Number or SSN" }

  let(:vet_id_column_header) do
    if FeatureToggle.enabled?(:decision_review_queue_ssn_column)
      "Veteran SSN"
    else
      "Veteran Participant Id"
    end
  end

  let(:vet_a_id_column_value) do
    if FeatureToggle.enabled?(:decision_review_queue_ssn_column)
      veteran_a.ssn
    else
      veteran_a.participant_id
    end
  end

  let(:vet_b_id_column_value) do
    if FeatureToggle.enabled?(:decision_review_queue_ssn_column)
      veteran_b.ssn
    else
      veteran_b.participant_id
    end
  end

  let(:vet_c_id_column_value) do
    if FeatureToggle.enabled?(:decision_review_queue_ssn_column)
      veteran_c.ssn
    else
      veteran_c.participant_id
    end
  end

  def current_table_rows
    find_all("#case-table-description > tbody > tr").map(&:text)
  end

  before do
    User.stub = user
    non_comp_org.add_user(user)
    FeatureToggle.enable!(:board_grant_effectuation_task)
  end

  context "with an existing organization" do
    after { FeatureToggle.disable!(:board_grant_effectuation_task) }

    scenario "displays tasks page with decision_review_queue_ssn_column feature toggle disabled" do
      visit BASE_URL
      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("In progress tasks")
      expect(page).to have_content("Completed tasks")

      # default is the in progress page
      expect(page).to have_content("Days Waiting")
      expect(page).to have_content("Higher-Level Review", count: 2)
      expect(page).to have_content("Board Grant")
      expect(page).to have_content(veteran_a.name)
      expect(page).to have_content(veteran_b.name)
      expect(page).to have_content(veteran_c.name)
      expect(page).to have_content(vet_id_column_header)
      expect(page).to have_content(vet_a_id_column_value)
      expect(page).to have_content(vet_b_id_column_value)
      expect(page).to have_content(vet_c_id_column_value)
      expect(page).to have_no_content(search_box_label)

      # ordered by assigned_at descending

      expect(page).to have_content(
        /#{veteran_b.name}.+\s#{veteran_c.name}.+\s#{veteran_a.name}/
      )

      click_on "Completed tasks"
      expect(page).to have_content("Higher-Level Review", count: 2)
      expect(page).to have_content("Date Completed")

      # ordered by closed_at descending
      expect(page).to have_content(
        Regexp.new(
          /#{veteran_b.name} #{vet_b_id_column_value} 1/,
          /#{request_issue_b.decision_date.strftime("%m\/%d\/%y")} Higher-Level Review/
        )
      )
    end

    context "with user enabled for intake" do
      scenario "displays tasks page" do
        visit BASE_URL
        expect(page).to have_content("Non-Comp Org")
        expect(page).to have_content("In progress tasks")
        expect(page).to have_content("Completed tasks")

        # default is the in progress page
        expect(page).to have_content("Days Waiting")
        expect(page).to have_content("Higher-Level Review", count: 2)
        expect(page).to have_content("Board Grant")
        expect(page).to have_content(veteran_a.name)
        expect(page).to have_content(veteran_b.name)
        expect(page).to have_content(veteran_c.name)
        expect(page).to have_content(vet_id_column_header)
        expect(page).to have_content(vet_a_id_column_value)
        expect(page).to have_content(vet_b_id_column_value)
        expect(page).to have_content(vet_c_id_column_value)
        expect(page).to have_no_content(search_box_label)

        click_on veteran_a.name
        expect(page).to have_content("Form created by")
      end
    end

    scenario "ordering reviews with participate id visable" do
      visit BASE_URL

      order_buttons = {
        claimant_name: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[1]/span/span[2]'),
        participant_id: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[2]/span/span[2]'),
        issues_count: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[3]/span/span[2]'),
        days_waiting: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span[1]/span[2]'),
        date_completed: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span/span[2]')
      }

      # Claimant name desc
      order_buttons[:claimant_name].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.first.include?("Aaa")).to eq true
      expect(table_rows.last.include?("Ccc")).to eq true

      # Claimant name asc
      order_buttons[:claimant_name].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=desc"
      )
      table_rows = current_table_rows

      expect(table_rows.first.include?("Ccc")).to eq true
      expect(table_rows.last.include?("Aaa")).to eq true

      # Participant ID desc
      order_buttons[:participant_id].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=asc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(hlr_b.veteran.participant_id)).to eq true
      expect(table_rows.first.include?(hlr_a.veteran.participant_id)).to eq true

      # Participant ID asc
      order_buttons[:participant_id].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=desc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(hlr_a.veteran.participant_id)).to eq true
      expect(table_rows.first.include?(hlr_b.veteran.participant_id)).to eq true

      # Issue count desc
      order_buttons[:issues_count].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueCountColumn&order=asc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(" 2 ")).to eq true
      expect(table_rows.first.include?(" 1 ")).to eq true

      # Issue count asc
      order_buttons[:issues_count].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueCountColumn&order=desc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(" 1 ")).to eq true
      expect(table_rows.first.include?(" 2 ")).to eq true

      # Days waiting desc
      order_buttons[:days_waiting].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=daysWaitingColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.first.include?("6 days")).to eq true
      expect(table_rows.last.include?("0 days")).to eq true

      # Days waiting asc
      order_buttons[:days_waiting].click
      expect(page).to have_current_path(
        # This url is the same as the above due to page caching. The params don't update in QueueTable when cached
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=daysWaitingColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.first.include?("0 days")).to eq true
      expect(table_rows.last.include?("6 days")).to eq true

      # Date Completed desc
      # Currently swapping tabs does not correctly populate get params.
      # These statements will need to updated when that is fixed
      click_button("tasks-organization-queue-tab-1")

      later_date = Time.zone.now.strftime("%m/%d/%y")
      earlier_date = 2.days.ago.strftime("%m/%d/%y")

      order_buttons[:date_completed].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=completed&page=1&sort_by=completedDateColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(later_date)).to eq true
      expect(table_rows.first.include?(earlier_date)).to eq true

      # Date Completed asc
      order_buttons[:date_completed].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=completed&page=1&sort_by=completedDateColumn&order=desc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(earlier_date)).to eq true
      expect(table_rows.first.include?(later_date)).to eq true
    end

    context "with veteran ssn visable" do
      before { FeatureToggle.enable!(:decision_review_queue_ssn_column) }
      after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

      scenario "ordering reviews" do
        visit BASE_URL

        ssn = find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[2]/span/span[2]')

        # Veteran SSN ascending
        ssn.click
        expect(page).to have_current_path(
          "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranSsnColumn&order=asc"
        )

        table_rows = current_table_rows

        expect(table_rows.last.include?(hlr_b.veteran.ssn)).to be == true
        expect(table_rows.first.include?(hlr_c.veteran.ssn)).to be == true

        # Veteran SSN descending
        ssn.click
        expect(page).to have_current_path(
          "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranSsnColumn&order=desc"
        )

        table_rows = current_table_rows

        expect(table_rows.last.include?(hlr_c.veteran.ssn)).to be == true
        expect(table_rows.first.include?(hlr_b.veteran.ssn)).to be == true
      end
    end

    context("veteran with null first and last name") do
      let(:veteran_b) do
        create(:veteran, first_name: "", last_name: "", participant_id: "601111772")
      end

      scenario "sorting and displaying a veteran with a null first and last name" do
        visit BASE_URL

        order_buttons = {
          claimant_name: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[1]/span/span[2]'),
          participant_id: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[2]/span/span[2]'),
          issues_count: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[3]/span/span[2]'),
          days_waiting: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span[1]/span[2]'),
          date_completed: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span/span[2]')
        }

        # Claimant name desc
        order_buttons[:claimant_name].click
        expect(page).to have_current_path(
          "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=asc"
        )

        table_rows = current_table_rows

        expect(table_rows.last.include?("claimant")).to eq true
        expect(table_rows.first.include?("Aaa")).to eq true

        # Claimant name asc
        order_buttons[:claimant_name].click
        expect(page).to have_current_path(
          "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=desc"
        )
        table_rows = current_table_rows

        expect(table_rows.last.include?("Aaa")).to eq true
        expect(table_rows.first.include?("claimant")).to eq true

        # Has a clickable name "claimant"
        click_link "claimant"
        expect(page).to have_content("Review each issue and assign the appropriate dispositions")
      end
    end

    scenario "filtering reviews" do
      visit BASE_URL
      find(".unselected-filter-icon").click

      # Check that task counts are being transmitted correctly from backend
      expect(page).to have_content("Board Grant (1)")
      expect(page).to have_content("Higher-Level Review (2)")

      find("label", text: "Higher-Level Review").click
      expect(page).to have_content("Higher-Level Review")
      expect(page).to_not have_content("Board Grant")
      find(".cf-clear-filters-link").click
      expect(page).to have_content("Board Grant")
    end

    scenario "searching reviews by name" do
      visit BASE_URL

      # There should be 2 on the page
      expect(page).to have_content("Higher-Level Review", count: 2)

      fill_in "search", with: veteran_b.first_name

      # There should be 1 on the page with this information
      expect(page).to have_content("Higher-Level Review", count: 1)
      expect(page).to have_content(
        /#{veteran_b.name} #{veteran_b.participant_id} 1 0 days Higher-Level Review/
      )

      # Blank out the input and verify that there are once again 2 on the page
      fill_in("search", with: nil, fill_options: { clear: :backspace })
      expect(page).to have_content("Higher-Level Review", count: 2)
    end

    scenario "searching reviews by participant id" do
      visit BASE_URL

      # There should be 2 on the page
      expect(page).to have_content("Higher-Level Review", count: 2)

      fill_in "search", with: veteran_a.participant_id

      # There should be 1 on the page with this information
      expect(page).to have_content("Higher-Level Review", count: 1)
      expect(page).to have_content(
        /#{veteran_a.name} #{veteran_a.participant_id} 2 6 days Higher-Level Review/
      )

      # Blank out the input and verify that there are once again 2 on the page
      fill_in("search", with: nil, fill_options: { clear: :backspace })
      expect(page).to have_content("Higher-Level Review", count: 2)
    end

    context "with decision_review_queue_ssn_column feature toggle enabled" do
      before { FeatureToggle.enable!(:decision_review_queue_ssn_column) }
      after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

      scenario "searching reviews by ssn" do
        visit "decision_reviews/nco"

        # There should be 2 on the page
        expect(page).to have_content("Higher-Level Review", count: 2)

        fill_in "search", with: veteran_a.ssn

        # There should be 1 on the page with this information
        expect(page).to have_content("Higher-Level Review", count: 1)
        expect(page).to have_content(
          /#{veteran_a.name} #{veteran_a.ssn} 2 6 days Higher-Level Review/
        )

        # Blank out the input and verify that there are once again 2 on the page
        fill_in("search", with: nil, fill_options: { clear: :backspace })
        expect(page).to have_content("Higher-Level Review", count: 2)
      end

      scenario "searching reviews by file number" do
        visit "decision_reviews/nco"

        # There should be 2 on the page
        expect(page).to have_content("Higher-Level Review", count: 2)

        fill_in "search", with: veteran_a.file_number

        # There should be 1 on the page with this information
        expect(page).to have_content("Higher-Level Review", count: 1)
        expect(page).to have_content(
          /#{veteran_a.name} #{veteran_a.ssn} 2 6 days Higher-Level Review/
        )

        # Blank out the input and verify that there are once again 2 on the page
        fill_in("search", with: nil, fill_options: { clear: :backspace })
        expect(page).to have_content("Higher-Level Review", count: 2)
      end
    end

    context "with user enabled for intake" do
      scenario "goes back to intake" do
        # allow user to have access to intake
        user.update(roles: user.roles << "Mail Intake")
        Functions.grant!("Mail Intake", users: [user.css_id])

        visit BASE_URL
        click_on "Intake new form"
        expect(page).to have_current_path("/intake")
      end
    end
  end

  context "with decision_review_queue_ssn_column feature toggle enabled" do
    before { FeatureToggle.enable!(:decision_review_queue_ssn_column) }
    after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

    scenario "displays tasks page" do
      visit BASE_URL
      expect(page).to have_content(vet_id_column_header)
      expect(page).to have_content(vet_a_id_column_value)
      expect(page).to have_content(vet_b_id_column_value)
      expect(page).to have_content(vet_c_id_column_value)
      expect(page).to have_content(search_box_label)
    end
  end
end
