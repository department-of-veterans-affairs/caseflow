module IntakeHelpers
  def add_untimely_exemption_response(yes_or_no)
    expect(page).to have_content("The issue requested isn't usually eligible because its decision date is older")
    find_all("label", text: yes_or_no).first.click
    fill_in "Notes", with: "I am an exemption note"
    safe_click ".add-issue"
  end
end
