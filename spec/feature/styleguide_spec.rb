require "rails_helper"

RSpec.feature "Style Guide" do
  fscenario "renders and is accessible" do
    visit "/styleguide"
    expect(page).to have_content("Caseflow Commons")
  end
end
