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

  def setup_legacy_opt_in_appeals(veteran_file_number)
    # Active and eligible
    create(:legacy_appeal, vacols_case:
      create(:case, :status_active, bfkey: "vacols1", bfcorlid: "#{veteran_file_number}S", bfdnod: 3.days.ago, bfdsoc: 3.days.ago))

    # ankylosis of hip, limitation of thigh motion (extension)
    allow(AppealRepository).to receive(:issues).with("vacols1")
      .and_return([
                    Generators::Issue.build(id: "vacols1", vacols_sequence_id: 1, codes: %w[02 15 03 5250]),
                    Generators::Issue.build(id: "vacols1", vacols_sequence_id: 2, codes: %w[02 15 03 5251])
                  ])

    # Active and not eligible
    create(:legacy_appeal, vacols_case:
      create(:case, :status_active, bfkey: "vacols2", bfcorlid: "#{veteran_file_number}S", bfdnod: 4.years.ago, bfdsoc: 4.months.ago))

    # intervertebral disc syndrome, degenerative arthritis of the spine
    allow(AppealRepository).to receive(:issues).with("vacols2")
      .and_return([
                    Generators::Issue.build(id: "vacols2", vacols_sequence_id: 1, codes: %w[02 15 03 5243]),
                    Generators::Issue.build(id: "vacols2", vacols_sequence_id: 2, codes: %w[02 15 03 5242])
                  ])

    # Not active and eligible
    create(:legacy_appeal, vacols_case:
      create(:case, :status_complete, bfkey: "vacols3", bfcorlid: "#{veteran_file_number}S", bfdnod: 4.days.ago, bfdsoc: 4.days.ago))

    # impairment of hip, impairment of femur
    allow(AppealRepository).to receive(:issues).with("vacols3")
      .and_return([
                    Generators::Issue.build(id: "vacols3", vacols_sequence_id: 1, codes: %w[02 15 03 5254]),
                    Generators::Issue.build(id: "vacols3", vacols_sequence_id: 2, codes: %w[02 15 03 5255])
                  ])

    # Not active and not eligible
    create(:legacy_appeal, vacols_case:
      create(:case, :status_complete, bfkey: "vacols4", bfcorlid: "#{veteran_file_number}S", bfdnod: 4.years.ago, bfdsoc: 4.months.ago))

    # typhoid arthritis, caisson disease of bones
    allow(AppealRepository).to receive(:issues).with("vacols4")
      .and_return([
                    Generators::Issue.build(id: "vacols4", vacols_sequence_id: 1, codes: %w[02 15 03 5006]),
                    Generators::Issue.build(id: "vacols4", vacols_sequence_id: 2, codes: %w[02 15 03 5011])
                  ])
  end
end
