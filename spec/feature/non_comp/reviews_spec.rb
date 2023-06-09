# frozen_string_literal: true

feature "NonComp Reviews Queue", :postgres do
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "vha") }
  let(:user) { create(:default_user) }

  let(:veteran_a) { create(:veteran, first_name: "Aaa", participant_id: "12345", ssn: "140261454") }
  let(:veteran_b) { create(:veteran, first_name: "Bbb", participant_id: "601111772", ssn: "191097395") }
  let(:veteran_c) { create(:veteran, first_name: "Ccc", participant_id: "1002345", ssn: "128455943") }
  let(:hlr_a) { create(:higher_level_review, veteran_file_number: veteran_a.file_number) }
  let(:hlr_b) { create(:higher_level_review, veteran_file_number: veteran_b.file_number) }
  let(:hlr_c) { create(:higher_level_review, veteran_file_number: veteran_c.file_number) }
  let(:appeal) { create(:appeal, veteran: veteran_c) }

  let!(:request_issue_a) do
    create(:request_issue, :nonrating, nonrating_issue_category: "Caregiver | Other", decision_review: hlr_a)
  end
  let!(:request_issue_aa) do
    create(:request_issue, :nonrating, nonrating_issue_category: "CHAMPVA", decision_review: hlr_a)
  end
  let!(:request_issue_b) do
    create(:request_issue, :nonrating, nonrating_issue_category: "Camp Lejune Family Member", decision_review: hlr_b)
  end
  let!(:request_issue_c) do
    create(:request_issue, :nonrating, :removed, decision_review: hlr_c)
  end
  let!(:request_issue_d) do
    create(:request_issue,
           :nonrating,
           nonrating_issue_category: "Camp Lejune Family Member",
           decision_review: appeal,
           closed_at: 1.day.ago)
  end

  let(:today) { Time.zone.now }
  let(:last_week) { Time.zone.now - 7.days }

  BASE_URL = "/decision_reviews/vha"

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
      expect(page).to have_content("Issues")
      expect(page).to have_content("Issue Type")
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
        expect(page).to have_content("Issues")
        expect(page).to have_content("Issue Type")
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

    scenario "ordering reviews with participate id visible" do
      visit BASE_URL

      order_buttons = {
        claimant_name: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[1]/span/span[2]'),
        participant_id: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[2]/span/span[2]'),
        issues_count: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[3]/span/span[2]'),
        issues_type: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span/span[2]'),
        days_waiting: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[5]/span[1]/span[2]'),
        date_completed: find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[5]/span/span[2]')
      }

      # Claimant name asc
      order_buttons[:claimant_name].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.first.include?("Aaa")).to eq true
      expect(table_rows.last.include?("Ccc")).to eq true

      # Claimant name desc
      order_buttons[:claimant_name].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=desc"
      )
      table_rows = current_table_rows

      expect(table_rows.first.include?("Ccc")).to eq true
      expect(table_rows.last.include?("Aaa")).to eq true

      # Participant ID asc
      order_buttons[:participant_id].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=asc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(hlr_b.veteran.participant_id)).to eq true
      expect(table_rows.first.include?(hlr_a.veteran.participant_id)).to eq true

      # Participant ID desc
      order_buttons[:participant_id].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=veteranParticipantIdColumn&order=desc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(hlr_a.veteran.participant_id)).to eq true
      expect(table_rows.first.include?(hlr_b.veteran.participant_id)).to eq true

      # Issue count asc
      order_buttons[:issues_count].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueCountColumn&order=asc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(" 2\n")).to eq true
      expect(table_rows.first.include?(" 1 ")).to eq true

      # Issue count desc
      order_buttons[:issues_count].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueCountColumn&order=desc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(" 1 ")).to eq true
      expect(table_rows.first.include?(" 2\n")).to eq true

      # Issue Types asc
      order_buttons[:issues_type].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueTypesColumn&order=asc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?("Caregiver | Other\nCHAMPVA\n")).to eq true
      expect(table_rows.first.include?(" Camp Lejune Family Member ")).to eq true

      # Issue Types desc
      order_buttons[:issues_type].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueTypesColumn&order=desc"
      )
      table_rows = current_table_rows

      expect(table_rows.last.include?(" Camp Lejune Family Member ")).to eq true
      expect(table_rows.first.include?("Caregiver | Other\nCHAMPVA")).to eq true

      # Days waiting asc
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

      # Date Completed asc
      # Currently swapping tabs does not correctly populate get params.
      # These statements will need to updated when that is fixed
      click_button("tasks-organization-queue-tab-1")

      later_date = Time.zone.now.strftime("%m/%d/%y")
      earlier_date = 2.days.ago.strftime("%m/%d/%y")

      order_buttons[:date_completed].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=completed&page=1&sort_by=completedDateColumn&order=desc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(earlier_date)).to eq true
      expect(table_rows.first.include?(later_date)).to eq true

      # Date Completed desc
      order_buttons[:date_completed].click
      expect(page).to have_current_path(
        "#{BASE_URL}?tab=completed&page=1&sort_by=completedDateColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?(later_date)).to eq true
      expect(table_rows.first.include?(earlier_date)).to eq true
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

        # Claimant name asc
        order_buttons[:claimant_name].click
        expect(page).to have_current_path(
          "#{BASE_URL}?tab=in_progress&page=1&sort_by=claimantColumn&order=asc"
        )

        table_rows = current_table_rows

        expect(table_rows.last.include?("claimant")).to eq true
        expect(table_rows.first.include?("Aaa")).to eq true

        # Claimant name desc
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

    scenario "filtering reviews by appeal type" do
      visit BASE_URL
      find("[aria-label='Filter by type']").click

      # Check that task counts are being transmitted correctly from backend
      expect(page).to have_content("Board Grant (1)")
      expect(page).to have_content("Higher-Level Review (2)")

      find("label", text: "Higher-Level Review").click
      expect(page).to have_content("Higher-Level Review")
      expect(page).to_not have_content("Board Grant")
      find(".cf-clear-filters-link").click
      expect(page).to have_content("Board Grant")
    end

    scenario "filtering reviews by issue type" do
      visit BASE_URL
      find("[aria-label='Filter by issue type']").click

      # Check that task counts are being transmitted correctly from backend
      expect(page).to have_content("Caregiver | Other (1)")
      expect(page).to have_content("Camp Lejune Family Member (1)")
      expect(page).to have_content("CHAMPVA (1)")

      find("label", text: "Caregiver | Other").click
      expect(page).to have_content("Caregiver | Other")
      expect(page).to_not have_content("Camp Lejune Family Member")
      find(".cf-clear-filters-link").click
      expect(page).to have_content("Camp Lejune Family Member")
    end

    scenario "searching reviews by name" do
      visit BASE_URL

      # There should be 2 on the page
      expect(page).to have_content("Higher-Level Review", count: 2)

      fill_in "search", with: veteran_b.first_name

      # There should be 1 on the page with this information
      expect(page).to have_content("Higher-Level Review", count: 1)
      expect(page).to have_content(
        /#{veteran_b.name} #{veteran_b.participant_id} 1 Camp Lejune Family Member 0 days Higher-Level Review/
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
        /#{veteran_a.name} #{veteran_a.participant_id} 2\nCaregiver | Other\nCHAMPVA\n 6 days Higher-Level Review/
      )

      # Blank out the input and verify that there are once again 2 on the page
      fill_in("search", with: nil, fill_options: { clear: :backspace })
      expect(page).to have_content("Higher-Level Review", count: 2)
    end

    context "with decision_review_queue_ssn_column feature toggle enabled" do
      before { FeatureToggle.enable!(:decision_review_queue_ssn_column) }
      after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }

      scenario "searching reviews by ssn" do
        visit BASE_URL

        # There should be 2 on the page
        expect(page).to have_content("Higher-Level Review", count: 2)

        fill_in "search", with: veteran_a.ssn

        # There should be 1 on the page with this information
        expect(page).to have_content("Higher-Level Review", count: 1)
        expect(page).to have_content(
          /#{veteran_a.name} #{veteran_a.ssn} 2\nCaregiver | Other\nCHAMPVA\n 6 days Higher-Level Review/
        )

        # Blank out the input and verify that there are once again 2 on the page
        fill_in("search", with: nil, fill_options: { clear: :backspace })
        expect(page).to have_content("Higher-Level Review", count: 2)
      end

      scenario "searching reviews by file number" do
        visit BASE_URL

        # There should be 2 on the page
        expect(page).to have_content("Higher-Level Review", count: 2)

        fill_in "search", with: veteran_a.file_number

        # There should be 1 on the page with this information
        expect(page).to have_content("Higher-Level Review", count: 1)
        expect(page).to have_content(
          /#{veteran_a.name} #{veteran_a.ssn} 2\nCaregiver | Other\nCHAMPVA\n 6 days Higher-Level Review/
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

  context "Issue Type filtering and sorting edge cases" do
    before { FeatureToggle.enable!(:decision_review_queue_ssn_column) }
    after { FeatureToggle.disable!(:decision_review_queue_ssn_column) }
    let(:veteran_a) { create(:veteran, first_name: "A Veteran", participant_id: "55555", ssn: "140261454") }
    let(:veteran_b) { create(:veteran, first_name: "B Veteran", participant_id: "66666", ssn: "140261455") }
    let(:veteran_c) { create(:veteran, first_name: "C Veteran", participant_id: "77777", ssn: "140261456") }
    let(:veteran_d) { create(:veteran, first_name: "D Veteran", participant_id: "88888", ssn: "140261457") }
    let(:hlr_a) { create(:higher_level_review, veteran_file_number: veteran_a.file_number) }
    let(:hlr_b) { create(:higher_level_review, veteran_file_number: veteran_b.file_number) }
    let(:hlr_c) { create(:higher_level_review, veteran_file_number: veteran_c.file_number) }
    let(:sc_a) { create(:supplemental_claim, veteran_file_number: veteran_d.file_number) }

    let!(:hlr_a_request_issues) do
      [
        create(:request_issue, :nonrating, nonrating_issue_category: "Other", decision_review: hlr_a),
        create(:request_issue, :nonrating, nonrating_issue_category: "Clothing Allowance", decision_review: hlr_a),
        create(:request_issue, :nonrating, nonrating_issue_category: "Beneficiary Travel", decision_review: hlr_a)
      ]
    end

    let!(:hlr_b_request_issues) do
      [
        create(:request_issue, :nonrating,
               nonrating_issue_category: "Spina Bifida Treatment (Non-Compensation)", decision_review: hlr_b),
        create(:request_issue, :nonrating, nonrating_issue_category: "Other", decision_review: hlr_b)
      ]
    end

    let!(:hlr_c_request_issues) do
      [
        create(:request_issue, :nonrating,
               nonrating_issue_category: "Eligibility for Dental Treatment", decision_review: hlr_c),
        create(:request_issue, :nonrating, nonrating_issue_category: "Beneficiary Travel", decision_review: hlr_c),
        create(:request_issue, :nonrating, nonrating_issue_category: "Beneficiary Travel", decision_review: hlr_c)
      ]
    end

    let!(:sc_a_request_issues) do
      [
        create(:request_issue, :nonrating,
               nonrating_issue_category: "Foreign Medical Program", decision_review: sc_a),
        create(:request_issue, :nonrating, nonrating_issue_category: "Camp Lejune Family Member", decision_review: sc_a)
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
               assigned_at: last_week),
        create(:higher_level_review_task,
               :in_progress,
               appeal: hlr_c,
               assigned_to: non_comp_org,
               assigned_at: last_week),
        create(:supplemental_claim_task,
               :in_progress,
               appeal: sc_a,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      ]
    end

    # rubocop:disable Layout/LineLength
    scenario "Duplicate issue types like Beneficiary Travel should be removed from the visible list of issue types" do
      visit BASE_URL
      hlr_c_regex = /#{veteran_c.name} #{veteran_c.ssn} 3\nBeneficiary Travel\nEligibility for Dental Treatment\n6 days Higher-Level Review/
      expect(page).to have_content(
        hlr_c_regex
      )
    end
    # rubocop:enable Layout/LineLength

    scenario "Ordering issue types should ignore duplicates when ordering" do
      visit BASE_URL

      issues_type_sort_button = find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span/span[2]')

      issues_type_sort_button.click

      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueTypesColumn&order=asc"
      )

      table_rows = current_table_rows

      expect(table_rows.last.include?("B Veteran")).to eq true
      expect(table_rows[1].include?("C Veteran")).to eq true
      expect(table_rows.first.include?("A Veteran")).to eq true

      issues_type_sort_button.click

      table_rows = current_table_rows

      expect(page).to have_current_path(
        "#{BASE_URL}?tab=in_progress&page=1&sort_by=issueTypesColumn&order=desc"
      )

      expect(table_rows.last.include?("A Veteran")).to eq true
      expect(table_rows[1].include?("D Veteran")).to eq true
      expect(table_rows.first.include?("B Veteran")).to eq true
    end

    scenario "The Issue type column should orderable and filterable at the same time" do
      visit BASE_URL
      issues_type_sort_button = find(:xpath, '//*[@id="case-table-description"]/thead/tr/th[4]/span/span[2]')

      # Filter by Beneficiary Travel
      find("[aria-label='Filter by issue type']").click
      find("label", text: "Beneficiary Travel").click
      expect(page).to have_content("Beneficiary Travel")
      expect(page).to_not have_content("Foreign Medical Program")

      # Filter by Foreign Medical Program
      # Need a *= matcher because the aria-label is appended with all the filtered types for some reason.
      find("[aria-label*='Filter by issue type']").click
      find("label", text: "Foreign Medical Program").click

      expect(page).to have_content("Beneficiary Travel")
      expect(page).to_not have_content("Spina Bifida Treatment (Non-Compensation)")
      expect(page).to have_content("Foreign Medical Program")

      table_rows = current_table_rows

      expect(table_rows.first.include?("A Veteran")).to eq true
      expect(table_rows.last.include?("D Veteran")).to eq true

      issues_type_sort_button.click

      table_rows = current_table_rows

      expect(table_rows.first.include?("A Veteran")).to eq true
      expect(table_rows.last.include?("D Veteran")).to eq true

      issues_type_sort_button.click

      table_rows = current_table_rows

      expect(table_rows.first.include?("D Veteran")).to eq true
      expect(table_rows.last.include?("A Veteran")).to eq true

      find(".cf-clear-filters-link").click
      expect(page).to have_content("Spina Bifida Treatment (Non-Compensation)")

      table_rows = current_table_rows
      expect(table_rows.first.include?("B Veteran")).to eq true
      expect(table_rows.last.include?("A Veteran")).to eq true
    end

    context "filtering when the request issue category has a | in it" do
      let!(:extra_task) do
        create(:higher_level_review_task,
               :in_progress,
               appeal: hlr_e,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end
      let!(:extra_completed_task) do
        create(:higher_level_review_task,
               :completed,
               appeal: hlr_f,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end
      let(:veteran_e) do
        create(:veteran, first_name: "In Progress Pipe Veteran", participant_id: "77989", ssn: "140261458")
      end
      let(:hlr_e) { create(:higher_level_review, veteran_file_number: veteran_e.file_number) }
      let(:veteran_f) do
        create(:veteran, first_name: "Completed Pipe Veteran", participant_id: "77990", ssn: "140261459")
      end
      let(:hlr_f) { create(:higher_level_review, veteran_file_number: veteran_f.file_number) }
      let(:pipe_issue_category) { "Caregiver | Eligibility" }
      let!(:pipe_request_issues) do
        [
          create(:request_issue, :nonrating,
                 nonrating_issue_category: pipe_issue_category, decision_review: hlr_e),
          create(:request_issue, :nonrating,
                 nonrating_issue_category: pipe_issue_category, decision_review: hlr_f)
        ]
      end

      let(:url_with_params) do
        BASE_URL + "?tab=in_progress&page=1&filter%5B%5D=col%3DissueTypesColumn%26val%3DCaregiver%20%7C%20Eligibility"
      end

      let!(:dispositions_url) { BASE_URL + "/tasks/#{extra_task.id}" }

      scenario "Using a filter from the get url paramaters that contains a '|' character" do
        visit url_with_params
        expect(page).to have_content("Caregiver | Eligibility")
        expect(page).to have_content("Filtering by: Issue Type (1)")
        expect(page).to_not have_content("Beneficiary Travel")
      end

      scenario "Preserving a filter when swapping between tabs that contains a '|' character" do
        visit BASE_URL

        # Expect an issue with foreign medical program to be on the page before filtering
        expect(page).to have_content("Foreign Medical Program")

        # Filter by Caregiver | Eligibility
        find("[aria-label='Filter by issue type']").click
        find("label", text: pipe_issue_category).click
        expect(page).to have_content(pipe_issue_category)
        expect(page).to_not have_content("Foreign Medical Program")
        expect(page).to have_content("Filtering by: Issue Type (1)")

        # Swap to the completed tab
        click_button("tasks-organization-queue-tab-1")
        expect(page).to have_content(pipe_issue_category)
        expect(page).to have_content("Filtering by: Issue Type (1)")

        # Swap back to the in progress tab
        click_button("tasks-organization-queue-tab-0")
        expect(page).to have_content(pipe_issue_category)
        expect(page).to_not have_content("Foreign Medical Program")
        expect(page).to have_content("Filtering by: Issue Type (1)")
      end

      # Simulate this by setting a filter, visiting the task page, and coming back
      scenario "Preserving the in progress filter after redirecting after completing a disposition" do
        visit BASE_URL

        # Expect an issue with foreign medical program to be on the page before filtering
        expect(page).to have_content("Foreign Medical Program")

        # Filter by Caregiver | Eligibility
        find("[aria-label='Filter by issue type']").click
        find("label", text: pipe_issue_category).click
        expect(page).to have_content(pipe_issue_category)
        expect(page).to_not have_content("Foreign Medical Program")
        expect(page).to have_content("Filtering by: Issue Type (1)")

        # Visit a task page
        visit dispositions_url
        expect(page).to have_content("Review each issue and assign the appropriate dispositions.")

        # Return to the in progress tab
        visit BASE_URL
        expect(page).to have_content(pipe_issue_category)
        expect(page).to_not have_content("Foreign Medical Program")
        expect(page).to have_content("Filtering by: Issue Type (1)")

        # Visit a task page again
        visit dispositions_url
        expect(page).to have_content("Review each issue and assign the appropriate dispositions.")

        # Return to the completed tab
        visit BASE_URL + "?tab=completed&page=1"
        expect(page).to have_content(pipe_issue_category)
        expect(page).to have_content("Filtering by: Issue Type (1)")
      end
    end
  end
end
