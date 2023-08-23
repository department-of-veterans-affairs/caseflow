# frozen_string_literal: true

require "rails_helper"

RSpec.describe Idt::Api::V2::DistributionsController, type: :controller do
  describe "#distribution" do
    let(:user) { create(:user) }
    let(:error_uuid) { "a9df0251-8350-464b-9aa4-a7d56a8ac173" }
    let(:distro_uuid) { "df7fc6b2-8be3-4124-a796-6a77bdd8f66a" }

    before do
      allow(SecureRandom).to receive(:uuid).and_return(error_uuid)

      key, t = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)

      request.headers["TOKEN"] = t
      create(:staff, :attorney_role, sdomainid: user.css_id)
    end

    context "when distribution_id is blank or invalid" do
      let(:distribution_id) { "" }
      let(:error_msg) do
        "[IDT] Http Status Code: 400, Distribution Does Not Exist Or Id is blank," \
          " (Distribution ID: #{distribution_id}) #{error_uuid}"
      end

      it "renders an error with status 400" do
        get :distribution, params: { distribution_id: distribution_id }

        expect(response.code).to eq "400"
        expect(JSON.parse(response.body)).to eq(
          "message" => error_msg
        )
      end
    end

    context "when PacmanService fails with a 404 error" do
      let!(:vbms_distribution) { create(:vbms_distribution) }

      it "renders the expected response with status 200, Pacman api has a 404" do
        expected_response = {
          "id" => vbms_distribution.id.to_s,
          "status" => "PENDING_ESTABLISHMENT"
        }

        get :distribution, params: { distribution_id: vbms_distribution.id }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end

    context "when PacmanService fails with a 500 error" do
      let(:error_msg) do
        "[IDT] Http Status Code: 500, Internal Server Error," \
          " (Distribution ID: #{vbms_distribution.id}) #{error_uuid}"
      end
      let(:vbms_distribution) { create(:vbms_distribution, uuid: distro_uuid) }

      it "renders an error with status 500" do
        allow(PacmanService).to receive(:get_distribution_request).with(vbms_distribution.uuid) do
          OpenStruct.new(code: 500)
        end

        get :distribution, params: { distribution_id: vbms_distribution.id }

        expect(response.code).to eq "500"
        expect(JSON.parse(response.body)).to eq(
          "message" => error_msg
        )
      end
    end

    context "when converting the distribution" do
      let(:vbms_distribution) { create(:vbms_distribution, uuid: distro_uuid) }
      let(:expected_response) do
        {
          "id": Fakes::PacmanService::DISTRIBUTION_UUID,
          "recipient":
          {
            "type": "system",
            "id": "a050a21e-23f6-4743-a1ff-aa1e24412eff",
            "name": "VBMS-C"
          },
          "description": "Staging Mailing Distribution",
          "communication_package_id": 1,
          "destinations": [
            {
              "type": "physicalAddress",
              "id": "28440040-51a5-4d2a-81a2-28730827be14",
              "status": "",
              "cbcm_send_attempt_date": "2022-06-06T16:35:27.996",
              "address_line_1": "POSTMASTER GENERAL",
              "address_line_2": "UNITED STATES POSTAL SERVICE",
              "address_line_3": "475 LENFANT PLZ SW RM 10022",
              "address_line_4": "SUITE 123",
              "address_line_5": "APO AE 09001-5275",
              "address_line_6": "",
              "treat_line_2_as_addressee": true,
              "treat_line_3_as_addressee": true,
              "city": "WASHINGTON DC",
              "state": "DC",
              "postal_code": "12345",
              "country_name": "UNITED STATES",
              "country_code": "us"
            }
          ],
          "status": "",
          "sent_to_cbcm_date": ""
        }
      end

      it "returns the expected converted response" do
        get :distribution, params: { distribution_id: vbms_distribution.id }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body.to_json)).to eq(expected_response.to_json)
      end
    end

    context "render_error" do
      let(:status) { 500 }
      let(:message) { "Internal Server Error" }
      let(:vbms_distribution) { create(:vbms_distribution, uuid: distro_uuid) }

      it "renders the error response with correct status, message, and distribution ID" do
        error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{vbms_distribution.id})"
        expect(Rails.logger).to receive(:error).with("#{error_message}Error ID: #{error_uuid}")

        allow(PacmanService).to receive(:get_distribution_request).with(distro_uuid) do
          OpenStruct.new(code: 500)
        end

        get :distribution, params: { distribution_id: vbms_distribution.id }

        expect(response).to have_http_status(status)
        expect(JSON.parse(response.body)).to eq(
          "message" => error_message + " #{error_uuid}"
        )
      end
    end

    context "format_response" do
      it "handles JSON parser errors" do
        invalid_json_response = double("response", raw_body: "invalid_json")

        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)

        expect(controller).to receive(:log_error)

        result = controller.send(:format_response, invalid_json_response)

        expect(result).to eq("invalid_json")
      end
    end
  end
end
