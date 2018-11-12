module IntakeHelpers
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

  def add_intake_rating_issue(description, note = nil)
    find_all("label", text: description).first.click
    fill_in("Notes", with: note) if note
    safe_click ".add-issue"
  end

  def add_intake_nonrating_issue(category:, description:, date:)
    safe_click ".no-matching-issues"
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
end
