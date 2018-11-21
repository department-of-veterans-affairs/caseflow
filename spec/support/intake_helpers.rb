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

  def add_intake_nonrating_issue(category:, description:, date:)
    expect(page.text).to match(/Does issue \d+ match any of these issue categories?/)
    expect(page).to have_button("Add this issue", disabled: true)
    fill_in "Issue category", with: category
    find("#issue-category").send_keys :enter
    fill_in "Issue description", with: description
    fill_in "Decision date", with: date
    expect(page).to have_button("Add this issue", disabled: false)
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
    # create two legacy appeals with 2 issues each
    create(:legacy_appeal, vacols_case:
      create(:case, bfkey: "vacols1", bfcorlid: "#{veteran_file_number}S", bfdnod: 3.days.ago, bfdsoc: 3.days.ago))
    create(:legacy_appeal, vacols_case:
      create(:case, bfkey: "vacols2", bfcorlid: "#{veteran_file_number}S", bfdnod: 4.days.ago, bfdsoc: 4.days.ago))
    allow(AppealRepository).to receive(:issues).with("vacols1")
      .and_return([
                    Generators::Issue.build(vacols_sequence_id: 1),
                    Generators::Issue.build(vacols_sequence_id: 1)
                  ])
    allow(AppealRepository).to receive(:issues).with("vacols2")
      .and_return([
                    Generators::Issue.build(vacols_sequence_id: 1),
                    Generators::Issue.build(vacols_sequence_id: 1)
                  ])
  end
end
