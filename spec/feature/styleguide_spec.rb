require "rails_helper"

# Future Style Guide Test...remove skip after fixing accessibility errors
# :nocov:
RSpec.feature "Style Guide" do
  skip "renders and is accessible" do
     visit "/styleguide"
     expect(page).to have_content("Caseflow Commons")
  end
end
# :nocov:
