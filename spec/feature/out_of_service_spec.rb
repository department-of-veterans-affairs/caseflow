require "rails_helper"

RSpec.feature "Out of Service" do
  context "Across all apps" do
    after do
      Rails.cache.write("out_of_service", false)
    end

    scenario "Out of service is disabled" do
      visit "/"
      expect(page).not_to have_content("Technical Difficulties")
    end

    scenario "Out of service is enabled" do
      Rails.cache.write("out_of_service", true)
      visit "/"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Certification" do
    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }

    after do
      Rails.cache.write("certification_out_of_service", false)
    end

    scenario "Out of service is disabled" do
      visit "certifications/new/5555C"
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "Out of service is enabled" do
      Rails.cache.write("certification_out_of_service", true)
      visit "certifications/new/5555C"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Reader" do
    after do
      Rails.cache.write("reader_out_of_service", false)
    end

    scenario "Out of service is disabled" do
      visit "reader/appeal/"
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "Out of service is enabled" do
      Rails.cache.write("reader_out_of_service", true)
      visit "reader/appeal/"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Hearings Prep" do
    after do
      Rails.cache.write("hearings_prep_out_of_service", false)
    end

    scenario "Out of service is disabled" do
      visit "certifications/new/5555C"
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "Out of service is enabled" do
      Rails.cache.write("hearings_prep_out_of_service", true)
      visit "certifications/new/5555C"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Dispatch" do
    let!(:current_user) { User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"]) }

    after do
      Rails.cache.write("dispatch_out_of_service", false)
    end

    scenario "Out of service is disabled" do
      visit "dispatch/establish-claim"
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "Out of service is enabled" do
      Rails.cache.write("dispatch_out_of_service", true)
      visit "dispatch/establish-claim"
      expect(page).to have_content("Technical Difficulties")
    end
  end
end
