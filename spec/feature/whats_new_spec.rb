require "rails_helper"

RSpec.feature "What's New" do

  scenario "Initial visit shows what's new indicator" do
    visit "certifications/new/1234C"
    expect(find("#whats-new-item")["class"]).to eq("cf-nav-whatsnew")
  end

  scenario "What's new indicator is reset after visiting /whats-new" do
    visit "certifications/new/1234C"
    expect(find("#whats-new-item")["class"]).to eq("cf-nav-whatsnew")
    visit "/whats-new"
    expect(find("#whats-new-item")["class"]).to be_falsy
  end
end