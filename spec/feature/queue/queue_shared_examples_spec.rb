# frozen_string_literal: true

# This needs setup variables
# Example Structs are below:
# Queue = Struct.new(:tabs)
# Tab = Struct.new(:tab_name, :tab_columns, :tab_body_text, :number_of_tasks)
# Example of variables:
# let(:column_headings) { ["Column Heading 1", "Column Heading 2"] }
# let!(:tabs) do
#   test_tab = Struct.new(:tab_name, :tab_columns, :tab_body_text, :number_of_tasks)
#   [
#     test_tab.new("Assigned", column_heading_names, "Cases assigned to you:", 12),
#     test_tab.new("In Progress", column_heading_names, "Cases that are in progress:", 0),
#     test_tab.new("Completed", column_heading_names, "Cases assigned to you:", 5)
#   ]
# end
# let!(:queue) { Struct.new(:tabs).new(tabs) }
RSpec.shared_examples "Standard Queue feature tests" do
  scenario "Queue has the correct tabs" do
    queue.tabs.each do |queue_tab|
      expect(page).to have_content queue_tab.tab_name
    end
  end

  scenario "Queue has the correct table columns" do
    queue.tabs.each do |queue_tab|
      click_button(queue_tab.tab_name)
      html_table_headings = all("th").map(&:text).reject(&:empty?).compact
      expect(page).to have_content queue_tab.tab_body_text
      expect(html_table_headings).to eq(queue_tab.tab_columns)
    end
  end

  scenario "Queue tab has the correct number of tasks" do
    queue.tabs.each do |queue_tab|
      tab_button = find("button", text: queue_tab.tab_name)
      tab_button.click
      num_table_rows = all("tbody > tr").count
      # Only check this if it's not the completed tab since that one often doesn't show a number
      if queue_tab.tab_name != "Completed"
        expect(tab_button.text).to eq("#{queue_tab.tab_name} (#{queue_tab.number_of_tasks})")
      end
      expect(num_table_rows).to eq(queue_tab.number_of_tasks)
    end
  end
end
