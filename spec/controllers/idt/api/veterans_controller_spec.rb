# frozen_string_literal: true

RSpec.describe Idt::Api::V1::VeteransController, :all_dbs, type: :controller do
  describe "GET /idt/api/v1/veterans" do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    it_behaves_like "IDT access verification", :get, :details

    context "when request header contains valid token" do
      let(:role) { :attorney_role }
      let(:file_number) { "111222333" }
      let!(:ssn) { "666660000" }
      let!(:veteran) do
        create(:veteran, file_number: file_number, ssn: ssn,
                         first_name: "Bob", last_name: "Smith", name_suffix: "II", sex: "M")
      end
      let(:power_of_attorney) { PowerOfAttorney.new(file_number: file_number) }
      let(:power_of_attorney_address) { power_of_attorney.bgs_representative_address }

      let(:veteran_hash) do
        {
          first_name: "Bob",
          last_name: "Smith",
          date_of_birth: veteran.person&.date_of_birth&.mdY,
          date_of_death: nil,
          name_suffix: "II",
          ssn: "987654321",
          sex: "M",
          address_line_1: "1234 Main Street",
          address_line_2: nil,
          address_line_3: nil,
          country: "USA",
          zip: "12345",
          state: "FL",
          city: "Orlando",
          file_number: "111222333"
        }
      end

      let(:poa_hash) do
        {
          representative_type: "Attorney",
          representative_name: "Clarence Darrow",
          address_line_1: "9999 MISSION ST",
          address_line_2: "UBER",
          address_line_3: "APT 2",
          city: "SAN FRANCISCO",
          country: "USA",
          state: "CA",
          zip: "94103"
        }
      end

      before do
        create(:staff, role, sdomainid: user.css_id)
        request.headers["TOKEN"] = token
      end

      context "POA is nil" do
        before do
          request.headers["FILENUMBER"] = file_number
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return(nil)
        end

        it "returns empty hash" do
          get :details

          expect(response.status).to eq 200

          response_body = JSON.parse(response.body)

          expect(response_body["poa"]).to eq({})
        end
      end

      context "POA has no address" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_return(nil)
          request.headers["FILENUMBER"] = file_number
        end

        it "returns just the POA name" do
          get :details

          response_body = JSON.parse(response.body)

          expect(response_body["poa"]).to eq(
            "representative_type" => "Attorney",
            "representative_name" => "Clarence Darrow",
            "participant_id" => power_of_attorney.bgs_participant_id
          )
        end
      end

      context "and a veteran's file number as a string" do
        before do
          request.headers["FILENUMBER"] = file_number
        end

        it "returns the veteran's details" do
          get :details
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["claimant"]

          expect(response_body["first_name"]).to eq veteran_hash[:first_name]
          expect(response_body["last_name"]).to eq veteran_hash[:last_name]
          expect(response_body["date_of_birth"]).to eq veteran_hash[:date_of_birth]
          expect(response_body["date_of_death"]).to eq veteran_hash[:date_of_death]
          expect(response_body["name_suffix"]).to eq veteran_hash[:name_suffix]
          expect(response_body["sex"]).to eq veteran_hash[:sex]
          expect(response_body["address_line_1"]).to eq veteran_hash[:address_line_1]
          expect(response_body["address_line_2"]).to eq veteran_hash[:address_line_2]
          expect(response_body["address_line_3"]).to eq veteran_hash[:address_line_3]
          expect(response_body["country"]).to eq veteran_hash[:country]
          expect(response_body["zip"]).to eq veteran_hash[:zip]
          expect(response_body["state"]).to eq veteran_hash[:state]
          expect(response_body["city"]).to eq veteran_hash[:city]
          expect(response_body["file_number"]).to eq veteran_hash[:file_number]
          expect(response_body["participant_id"]).not_to be_nil
          expect(response_body["participant_id"]).to eq veteran.participant_id
        end

        it "returns the veteran's poa" do
          get :details
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["poa"]

          expect(response_body["representative_type"]).to eq poa_hash[:representative_type]
          expect(response_body["representative_name"]).to eq poa_hash[:representative_name]
          expect(response_body["participant_id"]).not_to be_nil
          expect(response_body["participant_id"]).to eq power_of_attorney.bgs_participant_id
          expect(response_body["address_line_1"]).to eq poa_hash[:address_line_1]
          expect(response_body["address_line_2"]).to eq poa_hash[:address_line_2]
          expect(response_body["address_line_3"]).to eq poa_hash[:address_line_3]
          expect(response_body["country"]).to eq poa_hash[:country]
          expect(response_body["zip"]).to eq poa_hash[:zip]
          expect(response_body["state"]).to eq poa_hash[:state]
          expect(response_body["city"]).to eq poa_hash[:city]
        end
      end

      context "and a veteran's file number as a number" do
        before do
          request.headers["FILENUMBER"] = 111_222_333
        end

        it "returns the veteran's details and poa" do
          get :details
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)

          expect(response_body["claimant"]["first_name"]).to eq veteran_hash[:first_name]
          expect(response_body["claimant"]["last_name"]).to eq veteran_hash[:last_name]
          expect(response_body["claimant"]["date_of_birth"]).to eq veteran_hash[:date_of_birth]
          expect(response_body["claimant"]["date_of_death"]).to eq veteran_hash[:date_of_death]
          expect(response_body["claimant"]["name_suffix"]).to eq veteran_hash[:name_suffix]
          expect(response_body["claimant"]["sex"]).to eq veteran_hash[:sex]
          expect(response_body["claimant"]["address_line1"]).to eq veteran_hash[:address_line1]
          expect(response_body["claimant"]["country"]).to eq veteran_hash[:country]
          expect(response_body["claimant"]["zip"]).to eq veteran_hash[:zip]
          expect(response_body["claimant"]["state"]).to eq veteran_hash[:state]
          expect(response_body["claimant"]["city"]).to eq veteran_hash[:city]
          expect(response_body["claimant"]["file_number"]).to eq veteran_hash[:file_number]
          expect(response_body["claimant"]["participant_id"]).not_to be_nil
          expect(response_body["claimant"]["participant_id"]).to eq veteran.participant_id

          expect(response_body["poa"]["representative_type"]).to eq poa_hash[:representative_type]
          expect(response_body["poa"]["representative_name"]).to eq poa_hash[:representative_name]
          expect(response_body["poa"]["participant_id"]).not_to be_nil
          expect(response_body["poa"]["participant_id"]).to eq power_of_attorney.bgs_participant_id
          expect(response_body["poa"]["address_line_1"]).to eq poa_hash[:address_line_1]
          expect(response_body["poa"]["address_line_2"]).to eq poa_hash[:address_line_2]
          expect(response_body["poa"]["address_line_3"]).to eq poa_hash[:address_line_3]
          expect(response_body["poa"]["country"]).to eq poa_hash[:country]
          expect(response_body["poa"]["zip"]).to eq poa_hash[:zip]
          expect(response_body["poa"]["state"]).to eq poa_hash[:state]
          expect(response_body["poa"]["city"]).to eq poa_hash[:city]
        end
      end

      context "but no file number" do
        it "returns 422 unprocessable entity " do
          get :details
          message = JSON.parse(response.body)["message"]

          expect(response.status).to eq 422
          expect(message).to eq "Please enter a file number in the 'FILENUMBER' header"
        end
      end

      context "and no such veteran exists" do
        before { request.headers["FILENUMBER"] = "000000000" }

        it "returns 404 not found" do
          get :details
          response_body = JSON.parse(response.body)

          expect(response.status).to eq 404
          expect(response_body["message"]).to eq "Record not found"
        end
      end
    end
  end
end
