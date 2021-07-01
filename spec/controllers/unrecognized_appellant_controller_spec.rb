# frozen_string_literal: true

RSpec.describe UnrecognizedAppellantsController, :postgres, type: :controller do
  describe "PATCH /" do
    context "when user updates unrecognized appellant information" do
      let(:params) do
        {
          relationship: "updated",
          unrecognized_party_detail: {
            address_line_1: "updated_address",
            address_line_2: "updated_address_2"
          }
        }
      end

      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:ua) { create(:unrecognized_appellant) }

      it "should be successful" do
        patch :update, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        expect(response.status).to eq 200
      end
      it "should updated the UA and return the updated version" do
        original_relationship = "child"
        original_address_line_1 = "123 Park Ave"

        patch :update, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        
        response_body = JSON.parse(response.body)

        expect(response_body["relationship"]).to eq "updated"
        expect(response_body["unrecognized_party_detail"]["address_line_1"]).to eq "updated_address"
        expect(response_body["unrecognized_party_detail"]["address_line_2"]).to eq "updated_address_2"

        ua.reload

        expect(ua.current_version.relationship).to eq "updated"
        expect(ua.first_version.relationship).to eq original_relationship

        expect(ua.current_version.unrecognized_party_detail.address_line_1).to eq "updated_address"
        expect(ua.first_version.unrecognized_party_detail.address_line_1).to eq original_address_line_1
        expect(ua.versions.count).to eq 2
      end
      it "should return the non-updated version with a 400 if one of the updates fails" do
        allow_any_instance_of(UnrecognizedAppellant).to receive(:update).with(params.except(:unrecognized_party_detail)).and_raise(ActiveRecord::RecordInvalid)
      
        patch :update, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }

        response_body = JSON.parse(response.body)

        expect(response.status).to eq :bad_request
        expect(ua.versions.count).to eq 1
      end
    end
  end
end
