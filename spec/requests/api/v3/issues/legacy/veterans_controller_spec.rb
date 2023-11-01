# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ParenthesesAsGroupedExpression
describe Api::V3::Issues::Legacy::VeteransController, :postgres, type: :request do
  let_it_be(:api_key) do
    ApiKey.create!(consumer_name: "ApiV3 Test VBMS Consumer").key_string
  end

  let_it_be(:authorization_header) do
    { "Authorization" => "Token #{api_key}" }
  end

  describe "#show" do
    context "when feature is not enabled" do
      let!(:vet) { create(:veteran) }

      it "should return 'Not Implemented' error" do
        FeatureToggle.disable!(:api_v3_legacy_issues)
        get(
          "/api/v3/issues/legacy/find_by_veteran/#{vet.participant_id}",
          headers: authorization_header
        )
        expect(response).to have_http_status(501)
        expect(response.body).to include("Not Implemented")
      end
    end

    context "when feature is enabled" do
      before { FeatureToggle.enable!(:api_v3_legacy_issues) }
      after { FeatureToggle.disable!(:api_v3_legacy_issues) }

      context "when a veteran is not found" do
        it "should return veteran not found error" do
          get(
            "/api/v3/issues/legacy/find_by_veteran/9999999999",
            headers: authorization_header
          )
          expect(response).to have_http_status(404)
          expect(response.body).to include("No Veteran found for the given identifier")
        end
      end

      context "when a veteran is found" do
        context "when a veteran has no legacy appeal(s)" do
          let(:vet) { create(:veteran) }
          it "should return success" do
            get(
              "/api/v3/issues/legacy/find_by_veteran/#{vet.participant_id}",
              headers: authorization_header
            )
            expect(response).to have_http_status(200)
            expect(response.body).to include("No VACOLS Issues found for the given veteran")
          end
        end
        # context "when a veteran has legacy appeals(s)" do

        # end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ParenthesesAsGroupedExpression
