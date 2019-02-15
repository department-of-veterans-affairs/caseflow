RSpec.describe IntakesController do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:intake)
    User.authenticate!(roles: ["Mail Intake"])
  end

  describe "#create" do
    let(:file_number) { "123456789" }
    let(:ssn) { file_number.to_s.reverse } # our fakes do this
    let!(:veteran) { create(:veteran, file_number: file_number) }

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
      end
    end
  end

  describe "#complete" do
    # TODO: this is just testing the current implementation; should make this more behavioral
    it "should call complete! and return a 200" do
      intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
      intake.save!
      allow_any_instance_of(Intake).to receive(:complete!)
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
          expect do
            post :complete, params: { id: intake.id }
          end.to raise_error(Caseflow::Error::EstablishClaimFailedInVBMS)
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
      before { FeatureToggle.enable!(:intake, users: [current_user.css_id]) }

      it "should return the ui hash with ama_enabled being true" do
        intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
        intake.save!
        allow_any_instance_of(Intake).to receive(:complete!)
        allow_any_instance_of(Intake).to receive(:ui_hash).with(true)
      end
    end

    context "when intaking an AMA appeal" do
      before { FeatureToggle.disable!(:intake, users: [current_user.css_id]) }

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
end
