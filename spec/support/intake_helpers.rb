# rubocop:disable Metrics/ModuleLength
module IntakeHelpers
  def search_page_title
    "Search for Veteran by ID"
  end

  def search_bar_title
    "Enter the Veteran's ID"
  end

  def add_untimely_exemption_response(yes_or_no, note = "I am an exemption note")
    expect(page).to have_content("The issue requested isn't usually eligible because its decision date is older")
    find_all("label", text: yes_or_no).first.click
    fill_in "Notes", with: note
    safe_click ".add-issue"
  end

  def click_intake_add_issue
    safe_click "#button-add-issue"
  end

  def click_intake_finish
    safe_click "#button-finish-intake"
  end

  def click_intake_no_matching_issues
    safe_click ".no-matching-issues"
  end

  def add_intake_rating_issue(description, note = nil)
    # find_all with 'minimum' will wait like find() does.
    find_all("label", text: description, minimum: 1).first.click
    fill_in("Notes", with: note) if note
    safe_click ".add-issue"
  end

  def add_intake_nonrating_issue(category:, description:, date:, legacy_issues: false)
    add_button_text = legacy_issues ? "Next" : "Add this issue"
    expect(page.text).to match(/Does issue \d+ match any of these issue categories?/)
    expect(page).to have_button(add_button_text, disabled: true)
    fill_in "Issue category", with: category
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: description
    fill_in "Decision date", with: date
    expect(page).to have_button(add_button_text, disabled: false)
    safe_click ".add-issue"
  end

  def add_intake_unidentified_issue(description)
    safe_click ".no-matching-issues"
    safe_click ".no-matching-issues"
    expect(page).to have_content("Describe the issue to mark it as needing further review.")
    fill_in "Transcribe the issue as it's written on the form", with: description
    safe_click ".add-issue"
  end

  def click_remove_intake_issue(number)
    issue_el = find_intake_issue_by_number(number)
    issue_el.find(".remove-issue").click
  end

  def click_remove_issue_confirmation
    safe_click ".remove-issue"
  end

  def find_intake_issue_by_number(number)
    find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue"]').each do |node|
      if node.find(".issue-num").text =~ /^#{number}\./
        return node
      end
    end
  end

  def find_intake_issue_by_text(text)
    find_all(:xpath, './/div[@class="issues"]/*/div[@class="issue"]').each do |node|
      if node.text =~ /#{text}/
        return node
      end
    end
  end

  def find_intake_issue_number_by_text(text)
    find_intake_issue_by_text(text).find(".issue-num").text.delete(".")
  end

  def expect_ineligible_issue(number)
    expect(find_intake_issue_by_number(number)).to have_css(".not-eligible")
  end

  def expect_eligible_issue(number)
    expect(find_intake_issue_by_number(number)).to_not have_css(".not-eligible")
  end

  def setup_active_eligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols1",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 3.days.ago,
        bfdsoc: 3.days.ago,
        case_issues: [
          create(:case_issue, :ankylosis_of_hip), create(:case_issue, :limitation_of_thigh_motion_extension)
        ]
      ))
  end

  def setup_active_ineligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_active,
        bfkey: "vacols2",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.years.ago,
        bfdsoc: 4.months.ago,
        case_issues: [
          create(:case_issue, :intervertebral_disc_syndrome),
          create(:case_issue, :degenerative_arthritis_of_the_spine)
        ]
      ))
  end

  def setup_inactive_eligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_complete,
        bfkey: "vacols3",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.days.ago,
        bfdsoc: 4.days.ago,
        case_issues: [
          create(:case_issue, :impairment_of_hip),
          create(:case_issue, :impairment_of_femur)
        ]
      ))
  end

  def setup_inactive_ineligible_legacy_appeal(veteran_file_number)
    create(:legacy_appeal, vacols_case:
      create(
        :case,
        :status_complete,
        bfkey: "vacols4",
        bfcorlid: "#{veteran_file_number}S",
        bfdnod: 4.years.ago,
        bfdsoc: 4.months.ago,
        case_issues: [
          create(:case_issue, :typhoid_arthritis),
          create(:case_issue, :caisson_disease_of_bones)
        ]
      ))
  end

  def setup_legacy_opt_in_appeals(veteran_file_number)
    setup_active_eligible_legacy_appeal(veteran_file_number)
    setup_active_ineligible_legacy_appeal(veteran_file_number)
    setup_inactive_eligible_legacy_appeal(veteran_file_number)
    setup_inactive_ineligible_legacy_appeal(veteran_file_number)
  end
end
# rubocop:enable Metrics/ModuleLength
