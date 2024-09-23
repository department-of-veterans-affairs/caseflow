# frozen_string_literal: true

module DropdownHelpers
  def select_option(dropdown, text)
    dropdown.click
    dropdown.sibling(".cf-select__menu").find("div .cf-select__option", text: text).click
  end

  def perform_dropdown_actions(dropdowns)
    select_option(dropdowns[0], "Pre-docketing")
    select_option(dropdowns[1], "Intake 10182 Recv Needs AOJ Development")
    select_option(dropdowns[2], "Issues(s) is VHA")
    select_option(dropdowns[3], "N/A")
  end

  module_function :select_option, :perform_dropdown_actions
end
