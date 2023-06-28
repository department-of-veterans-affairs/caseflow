# frozen_string_literal: true

require "rails_helper"

# This is the command to run rspec in the console
# bundle exec rspec spec/controllers/idt/api/v2/distributions_controller_spec.rb

# Here is where you look at code coverage
# open coverage/index.html

RSpec.describe Idt::Api::V2::DistributionsController, type: :controller do
  describe "#get_distribution" do
    let(:user) { create(:user) }
    let(:distribution_id) { 123_456 }
    let(:appeal) { create(:appeal, :at_attorney_drafting) }
    let(:distribution) { create(:distribution, judge: JudgeTask.find_by(appeal: appeal).assigned_to) }
    let(:uuid) { "a9df0251-8350-464b-9aa4-a7d56a8ac173" }

    before do
      allow(controller).to receive(:params).and_return(distribution_id: distribution_id)
      allow(VbmsDistribution).to receive(:exists?).with(id: distribution_id).and_return(true)
      allow(PacmanService).to receive(:get_distribution_request).with(distribution_id).and_return(distribution)
      allow(SecureRandom).to receive(:uuid).and_return(uuid)
      key, t = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      request.headers["TOKEN"] = t
      create(:staff, :attorney_role, sdomainid: user.css_id)
    end

    context "when distribution_id is blank or invalid" do
      let(:distribution_id) { "" }
      let(:error_msg) do
        "[IDT] Http Status Code: 400, Distribution Does Not Exist Or Id is blank," \
          " (Distribution ID: #{distribution_id}) #{uuid}"
      end

      it "renders an error with status 400" do
        get :get_distribution, params: { distribution_id: distribution_id }
        expect(response.code).to eq "400"
        expect(JSON.parse(response.body)).to eq(
          "message" => error_msg
        )
      end
    end

    context "when PacmanService fails with a 404 error" do
      let(:distribution_id) { 123_456 }
      it "renders the expected response with status 200, Pacman api has a 404" do
        expected_response = {
          "id" => distribution_id,
          "status" => "PENDING_ESTABLISHMENT"
        }

        allow(PacmanService).to receive(:get_distribution_request).with(distribution_id) do
          OpenStruct.new(code: 404)
        end

        get :get_distribution, params: { distribution_id: distribution_id }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to eq(expected_response)
      end
    end

    context "when PacmanService fails with a 500 error" do
      let(:distribution) { double("Distribution", code: 500) }
      let(:error_msg) do
        "[IDT] Http Status Code: 500, Internal Server Error," \
          " (Distribution ID: #{distribution_id}) #{uuid}"
      end

      it "renders an error with status 500" do
        get :get_distribution, params: { distribution_id: distribution_id }
        expect(response.code).to eq "500"
        expect(JSON.parse(response.body)).to eq(
          "message" => error_msg
        )
      end
    end

    context "when converting the distribution" do
      let(:distribution_id) { 123_456 }
      let(:distribution) do
        HTTPI::Response.new(
          200,
          {},
          "id": distribution_id,
          "recipient": {
            "type": "system",
            "id": "a050a21e-23f6-4743-a1ff-aa1e24412eff",
            "name": "VBMS-C"
          },
          "description": "Staging Mailing Distribution",
          "communicationPackageId": "673c8b4a-cb7d-4fdf-bc4d-998d6d5d7431",
          "destinations": [{
            "type": "physicalAddress",
            "id": "28440040-51a5-4d2a-81a2-28730827be14",
            "status": "",
            "cbcmSendAttemptDate": "2022-06-06T16:35:27.996",
            "addressLine1": "POSTMASTER GENERAL",
            "addressLine2": "UNITED STATES POSTAL SERVICE",
            "addressLine3": "475 LENFANT PLZ SW RM 10022",
            "addressLine4": "SUITE 123",
            "addressLine5": "APO AE 09001-5275",
            "addressLine6": "",
            "treatLine2AsAddressee": true,
            "treatLine3AsAddressee": true,
            "city": "WASHINGTON DC",
            "state": "DC",
            "postalCode": "12345",
            "countryName": "UNITED STATES",
            "countryCode": "us"
          }],
          "status": "NEW",
          "sentToCbcmDate": ""
        )
      end

      before do
        allow(PacmanService).to receive(:get_distribution_request).with(distribution_id).and_return(distribution)
      end

      it "returns the expected converted response" do
        expected_response = {
          "id": distribution_id,
          "recipient": {
            "type": "system",
            "id": "a050a21e-23f6-4743-a1ff-aa1e24412eff",
            "name": "VBMS-C"
          },
          "description": "Staging Mailing Distribution",
          "communication_package_id": "673c8b4a-cb7d-4fdf-bc4d-998d6d5d7431",
          "destinations": [{
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
          }],
          "status": "NEW",
          "sent_to_cbcm_date": ""
        }
        get :get_distribution, params: { distribution_id: distribution_id }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body.to_json)).to eq(expected_response.to_json)
      end
    end

    context "render_error" do
      let(:status) { 500 }
      let(:message) { "Internal Server Error" }
      let(:distribution_id) { "123456" }

      it "renders the error response with correct status, message, and distribution ID" do
        error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"
        expect(Rails.logger).to receive(:error).with("#{error_message}Error ID: #{uuid}")

        allow(PacmanService).to receive(:get_distribution_request).with(distribution_id) do
          OpenStruct.new(code: 500)
        end

        get :get_distribution, params: { distribution_id: distribution_id }

        expect(response).to have_http_status(status)
        expect(JSON.parse(response.body)).to eq(
          "message" => error_message + " #{error_uuid}"
        )
      end
    end
  end
end
