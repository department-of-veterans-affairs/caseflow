# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Style Guide" do
  # :nocov:
  # The default Capybara driver would timeout on CircleCI pretty heavily.
  # The headless driver gets us the same result, but much faster
  # and more reliably, so we use it for this spec.
  before do
    Capybara.current_driver = :sniffybara_headless
  end
  after do
    Capybara.use_default_driver
  end
  scenario "renders and is accessible", skip: "test is flakey on CI" do
    visit "/styleguide"
    expect(page).to have_content("Caseflow Commons")
  end
  # :nocov:
end
