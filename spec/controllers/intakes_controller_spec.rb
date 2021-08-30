# frozen_string_literal: true

RSpec.describe IntakesController, :postgres do
  before do
    Fakes::Initializer.load!
    User.authenticate!(roles: ["Mail Intake"])

    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_call_original
    allow_any_instance_of(Veteran).to receive(:bgs).and_return(bgs)
    allow(bgs).to receive(:fetch_veteran_info).and_call_original
  end

  let(:bgs) { BGSService.new }

  describe "#create" do
    let(:file_number) { "123456788" }
    let(:ssn) { "666660000" }
    let!(:veteran) { create(:veteran, file_number: file_number, ssn: ssn) }

    it "should search by Veteran file number" do
      post :create, params: { file_number: file_number, form_type: "higher_level_review" }
      expect(response.status).to eq(200)
      expect(Intake.last.veteran_file_number).to eq(file_number)
    end

    it "should search by SSN" do
      post :create, params: { file_number: ssn, form_type: "higher_level_review" }
      expect(response.status).to eq(200)
      expect(Intake.last.veteran_file_number).to eq(file_number)
    end

    context "veteran name is out of sync with BGS" do
      let!(:veteran) { create(:veteran, file_number: file_number, first_name: nil, last_name: nil) }
      before { Generators::Veteran.build(file_number: file_number, first_name: "Ed", last_name: "Merica") }

      it "will update the Veteran name in Caseflow" do
        post :create, params: { file_number: file_number, form_type: "higher_level_review" }
        expect(response.status).to eq(200)
        vet = Veteran.find_by_file_number_or_ssn(file_number)
        expect(vet).to_not be_nil
        expect(vet.first_name).to eq "Ed"
        expect(vet.last_name).to eq "Merica"
        expect(bgs).to have_received(:fetch_veteran_info).exactly(4).times
      end
    end

    context "veteran in BGS but not yet in Caseflow" do
      let(:file_number) { "999887777" }
      let!(:veteran) {} # no-op
      before { Generators::Veteran.build(file_number: file_number, first_name: "Ed", last_name: "Merica") }

      it "will create the Veteran in Caseflow" do
        expect(Veteran.find_by_file_number_or_ssn(file_number)).to be_nil
        post :create, params: { file_number: file_number, form_type: "higher_level_review" }
        expect(response.status).to eq(200)
        vet = Veteran.find_by_file_number_or_ssn(file_number)
        expect(vet).to_not be_nil
        expect(vet.first_name).to eq "Ed"
        expect(vet.last_name).to eq "Merica"
        expect(bgs).to have_received(:fetch_veteran_info).exactly(2).times
      end
    end

    context "veteran in BGS with reserved file number" do
      let(:file_number) { "123456789" }
      let!(:veteran) {} # no-op
      before do
        Generators::Veteran.build(file_number: file_number, first_name: "Ed", last_name: "Merica")
        allow(Rails).to receive(:deploy_env?).and_return(true)
      end

      it "should search by reserved Veteran file number" do
        expect(Veteran.find_by_file_number_or_ssn(file_number)).to be_nil
        post :create, params: { file_number: file_number, form_type: "higher_level_review" }
        expect(response.status).to eq(422)
        expect(Intake.last.veteran_file_number).to eq(file_number)
      end
    end

    context "veteran in BGS and not accessible to user" do
      before do
        Generators::Veteran.build(file_number: file_number, first_name: "Ed", last_name: "Merica")
        allow_any_instance_of(Veteran).to receive(:accessible?).and_return(false)
      end

      let(:file_number) { "999887777" }
      let!(:veteran) {} # no-op

      it "does not create Veteran db record in Caseflow" do
        expect(Veteran.find_by_file_number_or_ssn(file_number)).to be_nil
        expect(Intake.find_by(veteran_file_number: file_number)).to be_nil
        post :create, params: { file_number: file_number, form_type: "higher_level_review" }
        expect(response.status).to eq(422)
        expect(controller.send(:new_intake).error_code).to eq("veteran_not_accessible")
        expect(Veteran.find_by_file_number_or_ssn(file_number)).to be_nil
        expect(Intake.find_by(veteran_file_number: file_number)).to_not be_nil
        expect(bgs).to have_received(:fetch_veteran_info).exactly(1).times
      end
    end

    context "veteran in BGS but user may not modify" do
      before do
        Generators::Veteran.build(file_number: file_number, first_name: "Ed", last_name: "Merica")
        allow_any_instance_of(Fakes::BGSService).to receive(:station_conflict?).and_return(true)
      end

      let(:file_number) { "999887777" }

      it "does not allow user to proceed with Intake" do
        post :create, params: { file_number: file_number, form_type: "higher_level_review" }

        expect(response.status).to eq(422)
        expect(controller.send(:new_intake).error_code).to eq("veteran_not_modifiable")
      end
    end
  end

  describe "#complete" do
    it "should call complete! and return a 200" do
      intake = create(:intake, user_id: current_user.id, started_at: Time.zone.now)
      allow(controller).to receive(:intake) { intake }
      allow(intake).to receive(:complete!) { true }
      post :complete, params: { id: intake.id }
      expect(response.status).to eq(200)
    end

    context "when Intake::complete! raises" do
      let(:unknown_error) do
        Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
      end
      context "a Caseflow::Error::EstablishClaimFailedInVBMS error" do
        it "should return a 500" do
          intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
          intake.save!
          allow_any_instance_of(Intake).to receive(:complete!).and_raise(unknown_error)
          post :complete, params: { id: intake.id }
          expect(response.status).to eq(500)
        end
      end

      context "a Caseflow::Error::DuplicateEp error" do
        let(:duplicate_ep_error) do
          Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(
            OpenStruct.new(body: "PIF is already in use")
          )
        end

        it "should return a 400" do
          intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
          intake.save!
          allow_any_instance_of(Intake).to receive(:complete!).and_raise(duplicate_ep_error)
          allow_any_instance_of(Intake).to receive(:detail).and_return(OpenStruct.new(end_product_description: "hello"))
          post :complete, params: { id: intake.id }
          expect(response.status).to eq(400)
        end
      end
    end

    context "when intaking an AMA appeal" do
      it "should return the ui hash with ama_enabled being true" do
        intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
        intake.save!
        allow_any_instance_of(Intake).to receive(:complete!)
        allow_any_instance_of(Intake).to receive(:ui_hash).with(true)
      end
    end

    context "when intaking an AMA appeal" do
      it "should return the ui hash with ama_enabled being false" do
        intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
        intake.save!
        allow_any_instance_of(Intake).to receive(:complete!)
        allow_any_instance_of(Intake).to receive(:ui_hash).with(false)
      end
    end

    context "when intaking a processed_in_caseflow AMA HLR/SC" do
      let(:veteran) { create(:veteran) }

      it "should return a JSON payload with a redirect_to path" do
        intake = create(:intake,
                        user: current_user,
                        detail: create(:higher_level_review,
                                       benefit_type: "education",
                                       veteran_file_number: veteran.file_number))

        post :complete, params: { id: intake.id }
        resp = JSON.parse(response.body, symbolize_names: true)

        expect(resp[:serverIntake]).to eq(redirect_to: "/decision_reviews/education")
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "#attorneys" do
    it "returns the names and participant IDs of matching attorneys" do
      create(:bgs_attorney, name: "JOHN SMITH", participant_id: "123")
      create(:bgs_attorney, name: "KEANU REEVES", participant_id: "456")

      get :attorneys, params: { query: "JON SMITH" }
      resp = JSON.parse(response.body, symbolize_names: true)
      expect(resp).to eq [
        {
          "address": {
              "address_line_1": "9999 MISSION ST",
              "address_line_2": "UBER",
              "address_line_3": "APT 2",
              "city": "SAN FRANCISCO",
              "country": "USA",
              "state": "CA",
              "zip": "94103"
            },
          "name": "JOHN SMITH",
          "participant_id": "123"
        }
      ]
    end
    it "works when the user is not an intake user" do
      User.unauthenticate!
      User.authenticate!(roles: ["NOT Mail Intake"])

      get :attorneys, params: { query: "JON SMITH" }

      expect(response.status).to eq(200)
    end
  end
end
