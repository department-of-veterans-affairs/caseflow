# frozen_string_literal: true

RSpec.describe UnrecognizedAppellantsController, :postgres, type: :controller do
  describe "PATCH /" do
    context "when user updates unrecognized appellant information" do
      let(:updated_relationship) { "updated" }
      let(:updated_address_1) { "updated_address_1" }
      let(:updated_address_2) { "updated_address_2" }
      let(:params) do
        {
          relationship: updated_relationship,
          unrecognized_party_detail: {
            address_line_1: updated_address_1,
            address_line_2: updated_address_2
          }
        }
      end

      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:ua) { create(:unrecognized_appellant) }

      it "should be successful" do
        patch :update, params: { id: ua.id, unrecognized_appellant: params }
        expect(response.status).to eq 200
      end
      it "should fail if update returns false" do
        allow_any_instance_of(UnrecognizedAppellant).to receive(:update_with_versioning!).and_return(false)

        patch :update, params: { id: ua.id, unrecognized_appellant: params }
        expect(response.status).to eq 400
      end
      it "should update the UA and return the updated version" do
        original_relationship = ua.relationship
        original_address_line_1 = ua.unrecognized_party_detail.address_line_1
        original_created_by = ua.created_by

        patch :update, params: { id: ua.id, unrecognized_appellant: params }

        response_body = JSON.parse(response.body)

        ua.reload

        expect(response_body["relationship"]).to eq updated_relationship
        expect(response_body["unrecognized_party_detail"]["address_line_1"]).to eq updated_address_1
        expect(response_body["unrecognized_party_detail"]["address_line_2"]).to eq updated_address_2

        expect(ua.current_version.relationship).to eq updated_relationship
        expect(ua.first_version.relationship).to eq original_relationship
        expect(ua.current_version.created_by).to eq user
        expect(ua.first_version.created_by).to eq original_created_by

        expect(ua.current_version.unrecognized_party_detail.address_line_1).to eq updated_address_1
        expect(ua.first_version.unrecognized_party_detail.address_line_1).to eq original_address_line_1
        expect(ua.versions.count).to eq 2
      end
      it "should return the non-updated version with a 400 if one of the updates fails" do
        # Default the return for the let(:ua)
        allow_any_instance_of(UnrecognizedAppellant).to receive(:update).and_return(:default)
        # Raise a RecordInvalid error when update is called
        allow_any_instance_of(UnrecognizedAppellant)
          .to receive(:update)
          .with(instance_of(ActionController::Parameters))
          .and_raise(ActiveRecord::RecordInvalid)
        original_relationship = ua.relationship

        patch :update, params: { id: ua.id, unrecognized_appellant: params }

        response_body = JSON.parse(response.body)

        ua.reload

        expect(response.status).to eq 400
        expect(response_body["relationship"]).to eq original_relationship
        expect(ua.relationship).to eq original_relationship
      end
    end
  end
  describe "PATCH /unrecognized_appellant/:id/power_of_attorney" do
    context "when user adds power_of_attorney_details" do
      let(:updated_address_1) { "updated_address_1" }
      let(:updated_address_2) { "updated_address_2" }
      let(:params) do
        {
          unrecognized_power_of_attorney: {
            address_line_1: updated_address_1,
            address_line_2: updated_address_2,
            name: "test",
            city: "city",
            state: "state",
            country: "country",
            party_type: "individual",
            zip: "12345"
          }
        }
      end
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:ua) { create(:unrecognized_appellant) }
      it "should be successful" do
        ua.update(unrecognized_power_of_attorney_id: nil)
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 200
        expect(ua.power_of_attorney.is_a?(UnrecognizedPowerOfAttorney))
        expect(ua.power_of_attorney.name).to eq "test"
        expect(ua.power_of_attorney.address_line_1).to eq updated_address_1
      end
      it "returns failure if unsuccessful" do
        ua.update(unrecognized_power_of_attorney_id: nil)
        allow_any_instance_of(UnrecognizedAppellant).to receive(:update_power_of_attorney!).and_return(false)
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 400
        expect(ua.power_of_attorney.nil?)
      end
      it "should be unsuccessful if UA already has a POA" do
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 400
      end
      it "fails gracefully if missing a required param" do
        ua.update(unrecognized_power_of_attorney_id: nil)
        params[:unrecognized_power_of_attorney][:city] = nil
        allow_any_instance_of(UnrecognizedAppellant).to receive(:update_power_of_attorney!).and_return(false)
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 400
        expect(ua.power_of_attorney.nil?)
      end
    end
    context "when user adds poa_participant_id" do
      let(:params) do
        {
          poa_participant_id: 123
        }
      end
      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:ua) { create(:unrecognized_appellant) }
      it "should be successful" do
        ua.update(unrecognized_power_of_attorney_id: nil)
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 200
        expect(ua.power_of_attorney.is_a?(AttorneyPowerOfAttorney))
        expect(ua.power_of_attorney.participant_id).to eq "123"
      end
      it "should be unsuccessful if UA already has a POA" do
        patch :update_power_of_attorney, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        ua.reload

        expect(response.status).to eq 400
      end
    end
  end
end
