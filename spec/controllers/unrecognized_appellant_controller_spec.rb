# frozen_string_literal: true

RSpec.describe UnrecognizedAppellantsController, :postgres, type: :controller do
  describe "PATCH /" do
    context "when user updates unrecognized appellant information" do
      let(:params) do
        {
          relationship: "child",
          unrecognized_party_detail: {}
        }
      end

      let!(:user) { User.authenticate!(roles: ["System Admin"]) }
      let(:ua) { create(:unrecognized_appellant) }

      it "should be successful" do
        patch :update, params: { unrecognized_appellant_id: ua.id, unrecognized_appellant: params }
        expect(response.status).to eq 200
      end
    end
  end
end
