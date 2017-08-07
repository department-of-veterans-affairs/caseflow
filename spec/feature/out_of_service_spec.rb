require "rails_helper"

RSpec.feature "Out of Service" do
  context "Across all apps" do
    after do
      Rails.cache.write("out_of_service", false)
    end

    scenario "When out of service is disabled, it shows Caseflow Home page" do
      visit "/"
      expect(page).to have_content("Caseflow Help")
      expect(page).not_to have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("out_of_service", true)
      visit "/"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Certification" do
    before do
      FeatureToggle.enable!(:certification_v2)
    end

    after do
      Rails.cache.write("certification_out_of_service", false)
      FeatureToggle.disable!(:certification_v2)
    end

    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }
    let(:nod) { Generators::Document.build(type: "NOD") }
    let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
    let(:form9) { Generators::Document.build(type: "Form 9") }

    let(:documents) { [nod, soc, form9] }
    let(:appeal_ready) do
      Generators::Appeal.build(vacols_record: vacols_record, documents: documents)
    end
    let(:vacols_record) do
      {
        template: :ready_to_certify,
        type: "Original",
        file_type: "VVA",
        representative: "The American Legion",
        veteran_first_name: "Davy",
        veteran_last_name: "Crockett",
        veteran_middle_initial: "X",
        appellant_first_name: "Susie",
        appellant_middle_initial: nil,
        appellant_last_name: "Crockett",
        appellant_relationship: "Daughter",
        nod_date: nod.received_at,
        soc_date: soc.received_at + 4.days,
        form9_date: form9.received_at
      }
    end

    scenario "When out of service is disabled, it shows Check Documents page" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content("Check Documents")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("certification_out_of_service", true)
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Reader" do
    before do
      FeatureToggle.enable!(:reader)

      Fakes::Initializer.load!
    end

    after do
      FeatureToggle.disable!(:reader)
      Rails.cache.write("reader_out_of_service", false)
    end

    let(:vacols_record) { :remand_decided }

    let(:documents) { [] }

    let!(:issue_levels) do
      ["Other", "Left knee", "Right knee"]
    end

    let!(:issues) do
      [Generators::Issue.build(disposition: :allowed,
                               program: :compensation,
                               type: { name: :elbow, label: "Elbow" },
                               category: :service_connection,
                               levels: issue_levels
                              )
      ]
    end

    let(:appeal) do
      Generators::Appeal.create(vacols_record: vacols_record, documents: documents, issues: issues)
    end

    let!(:current_user) do
      User.authenticate!(roles: ["Reader"])
    end

    scenario "When out of service is disabled, it shows document page" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Claims folder details")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("reader_out_of_service", true)
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Hearings Prep" do
    before do
      current_user.update!(full_name: "Lauren Roth", vacols_id: "LROTH")

      2.times do
        Generators::Hearing.build(
          user: current_user,
          date: 5.days.from_now,
          type: "video"
        )
      end

      Generators::Hearing.build(
        user: current_user,
        type: "central_office",
        date: Time.zone.now
      )
    end

    after do
      Rails.cache.write("hearings_prep_out_of_service", false)
    end

    let!(:current_user) do
      User.authenticate!(roles: ["Hearing Prep"])
    end

    scenario "When out of service is disabled, it shows Hearings page" do
      visit "/hearings/dockets"
      expect(page).to have_content("Upcoming Hearing Days")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("hearings_prep_out_of_service", true)
      visit "/hearings/dockets"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Dispatch" do
    after do
      Rails.cache.write("dispatch_out_of_service", false)
    end

    let!(:current_user) { User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"]) }

    let(:appeal) do
      Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
    end

    let(:vacols_record) { :remand_decided }

    scenario "When out of service is disabled, it shows Work Assignments page" do
      visit "dispatch/establish-claim"
      expect(page).to have_content("Your Work Assignments")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("dispatch_out_of_service", true)
      visit "dispatch/establish-claim"
      expect(page).to have_content("Technical Difficulties")
    end
  end
end
