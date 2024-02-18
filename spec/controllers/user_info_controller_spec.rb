# frozen_string_literal: true

describe UserInfoController, :postgres, type: :controller do
  describe ".represented_organizations" do
    let(:user) { create(:user) }
    let(:params) { {} }

    subject { get(:represented_organizations, params: params) }

    before do
      User.authenticate!(user: user)
    end

    context "when the requestor is not a BVA admin" do
      before do
        allow_any_instance_of(Bva).to receive(:user_has_access?).and_return(false)
      end

      it "redirects to unauthorized" do
        subject

        expect(response.status).to eq(302)
        expect(response.body).to match(/unauthorized/)
      end
    end

    context "when the requestor is a BVA admin" do
      before do
        allow_any_instance_of(Bva).to receive(:user_has_access?).and_return(true)
      end

      context "when there is no css_id parameter in the request" do
        let(:params) { { station_id: random_station_id } }

        it "returns an error" do
          subject

          expect(response.status).to eq(400)
          expect(response.body).to match(/css_id/)
        end
      end

      context "when the css_id parameter is invalid in the request" do
        let(:params) do
          {
            css_id: random_css_id + Generators::Random.special_characters,
            station_id: random_station_id
          }
        end

        it "returns an error" do
          subject

          expect(response.status).to eq(400)
          expect(response.body).to match(/css_id/)
        end
      end

      context "when the css_id is of lower or mixed case" do
        let(:params) do
          { css_id: random_css_id.downcase, station_id: random_station_id }
        end

        it "uppercases the css_id before sending to BGS" do
          bgs_client = instance_double("client")
          bgs_service = ExternalApi::BGSService.new(client: bgs_client) # not fake. mock client instead.
          security_service = instance_double("security")
          org_service = instance_double("org")

          allow(BGSService).to receive(:new) { bgs_service }
          allow(bgs_client).to receive(:security) { security_service }
          allow(bgs_client).to receive(:org) { org_service }

          expect(security_service).to receive(:find_participant_id).with(
            css_id: params[:css_id].upcase, station_id: params[:station_id]
          )
          expect(org_service).to receive(:find_poas_by_ptcpnt_id) { [] }

          subject
        end
      end

      context "when there is no station_id parameter in the request" do
        let(:params) { { css_id: random_css_id } }

        it "returns an error" do
          subject

          expect(response.status).to eq(400)
          expect(response.body).to match(/station_id/)
        end
      end

      context "when the station_id parameter is invalid in the request" do
        let(:params) do
          {
            css_id: random_css_id,
            station_id: random_station_id + Generators::Random.word_characters
          }
        end

        it "returns an error" do
          subject

          expect(response.status).to eq(400)
          expect(response.body).to match(/station_id/)
        end
      end

      context "when station_id and css_id parameters are valid" do
        let(:params) do
          {
            css_id: random_css_id,
            station_id: random_station_id
          }
        end

        it "makes requests to BGS" do
          bgs_service = instance_double(Fakes::BGSService)
          expect(BGSService).to receive(:new).and_return(bgs_service).exactly(2).times

          expect(bgs_service).to receive(:get_participant_id_for_css_id_and_station_id)
          expect(bgs_service).to receive(:fetch_poas_by_participant_id)

          subject
        end

        it "returns a valid response with the expected interface" do
          subject

          expect(response.status).to eq(200)

          response_body = JSON.parse(response.body)
          expect(response_body["represented_organizations"]).to eq([])
        end
      end
    end
  end
end

def random_station_id
  Generators::Random.from_set(("0".."9").to_a, 3)
end

def random_css_id
  Generators::Random.word_characters(24)
end
