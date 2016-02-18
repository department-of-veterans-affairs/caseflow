require "rails_helper"

RSpec.feature "What's New" do
  scenario "Initial visit shows what's new indicator" do
    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_not_ready }

    visit "certifications/new/1234C"
    expect(page).to have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
  end

  scenario "What's new indicator is reset after visiting /whats-new" do
    Fakes::AppealRepository.records = { "1234C" => Fakes::AppealRepository.appeal_not_ready }

    visit "certifications/new/1234C"
    expect(page).to have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
    visit "/whats-new"
    expect(page).to_not have_css("#whats-new-item.cf-nav-whatsnew", visible: false)
  end
end
