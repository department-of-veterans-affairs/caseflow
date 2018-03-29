RSpec.describe IntakesController do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:intake)
    User.authenticate!(roles: ["Mail Intake"])
  end

  describe "#complete" do
    # TODO: this is just testing the current implementation; should make this more behavioral
    it "should call complete! and return a 500" do
      intake = Intake.new(user_id: current_user.id, started_at: Time.zone.now)
      intake.save!
      allow_any_instance_of(Intake).to receive(:complete!)
      post :complete, id: intake.id
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
            post :complete, id: intake.id
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
          post :complete, id: intake.id
          expect(response.status).to eq(400)
        end
      end
    end
  end
end
