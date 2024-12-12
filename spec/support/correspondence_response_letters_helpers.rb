# frozen_string_literal: true

require_relative "dropdown_helpers"

module CorrespondenceResponseLettersHelpers
  include CorrespondenceHelpers
  include DropdownHelpers

  def initial_setup
    setup_access
    @correspondence = create(
      :correspondence,
      :with_correspondence_intake_task,
      assigned_to: current_user,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    find_and_route_to_intake
  end

  def setup_response_letters_data
    initial_setup
    perform_add_letters_action
    @correspondence
  end

  def perform_add_letters_action
    click_on("+ Add letter")
    dropdowns = page.all(".cf-select__control")
    select_option(dropdowns[0], "Pre-docketing")
    existing_letters_actions(dropdowns)
  end

  def perform_add_letter_popup_window
    add_popup_response_letter
  end

  def existing_letters_actions(dropdowns)
    perform_dropdown_actions(dropdowns)
    click_button("Continue")
    click_button("Continue")
    click_button("Submit")
    click_button("Confirm")
  end

  def response_letters_order_actions
    initial_setup
    expired_response_letters
  end

  def add_popup_response_letter
    click_button("+ Add letter")
    all("#date-set")[0].click
    ten_days_before = 10.days.ago.strftime("%m/%d/%Y")
    all("#date-set")[0].fill_in(with: ten_days_before)
    dropdowns = page.all(".cf-select__control")
    select_option(dropdowns[0], "General")
    click_popup_dropdown_item_by_text(dropdowns)
  end

  def click_popup_dropdown_item_by_text(dropdowns)
    perform_dropdown_actions(dropdowns)
    page.execute_script("document.querySelector('.cf-form-radio-options').scrollIntoView();")
    page.execute_script(
      "document.getElementById(" \
      "'How-long-should-the-response-window-be-for-this-response-letter-undefined_Custom')" \
      ".click()"
    )

    find_by_id("content").fill_in with: "2"
    click_on("Add")
    @correspondence
  end

  def expired_response_letters
    click_on("+ Add letter")
    all("#date-set")[0].click
    ten_days_before = 10.days.ago.strftime("%m/%d/%Y")
    all("#date-set")[0].fill_in(with: ten_days_before)
    dropdowns = page.all(".cf-select__control")
    select_option(dropdowns[0], "Untimely")
    click_dropdown_item_by_text(dropdowns)
  end

  def click_dropdown_item_by_text(dropdowns)
    perform_dropdown_actions(dropdowns)
    page.execute_script(
      "document.getElementById('How-long-should-the-response-window-be-for-this-response-letter-1_Custom').click()"
    )
    find_by_id("content").fill_in with: "2"
    add_second_response_letter
    @correspondence
  end

  def wait_for_backend_processing
    sleep 2
  end

  def add_second_response_letter
    click_on("+ Add letter")
    container = find_by_id("2")
    dropdowns = container.all(".cf-select__control")
    select_option(dropdowns[0], "Pre-docketing")
    existing_letters_actions(dropdowns)
  end
end
