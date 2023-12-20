# frozen_string_literal: true

describe "appeals" do
  include_context "rake"

  describe "appeals:change_vacols_location" do
    let(:loc_case_storage) { LegacyAppeal::LOCATION_CODES[:case_storage] }
    let(:loc_service_org) { LegacyAppeal::LOCATION_CODES[:service_organization] }
    let(:loc_transcription) { LegacyAppeal::LOCATION_CODES[:transcription] }

    let(:loc1) { loc_service_org }
    let(:vc1) { create(:case, bfcurloc: loc1) }
    let!(:la1) { create(:legacy_appeal, vacols_case: vc1) }

    let(:loc2) { loc_service_org }
    let(:vc2) { create(:case, bfcurloc: loc2) }
    let!(:la2) { create(:legacy_appeal, vacols_case: vc2) }

    let(:args) { [] }

    subject do
      Rake::Task["appeals:change_vacols_location"].reenable
      Rake::Task["appeals:change_vacols_location"].invoke(*args)
    end

    context "expected values are passed" do
      context "no dry run variable is passed" do
        let(:output_match) { /\*\*\* DRY RUN/ }
        let(:args) { [loc_service_org, loc_case_storage, la1.vacols_id, la2.vacols_id] }

        it "doesn't change the appeals' location" do
          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_service_org
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_service_org

          expect { subject }.to output(output_match).to_stdout

          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_service_org
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_service_org
        end
      end

      context "dry run is set to false" do
        let(:output_match) do
          /Moved 2 of 2 legacy appeals from location #{loc_service_org} to #{loc_case_storage}./
        end
        let(:args) { [loc_service_org, loc_case_storage, false, la1.vacols_id, la2.vacols_id] }

        it "moves the appeals to the new location" do
          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_service_org
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_service_org

          expect { subject }.to output(output_match).to_stdout

          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_case_storage
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_case_storage
        end
      end

      context "appeals are passed that aren't in the expected location" do
        let(:loc1) { loc_transcription }
        let(:output_match) do
          /vacols_id #{la1.vacols_id} is in location #{loc_transcription}, not #{loc_service_org}; skipping./
        end
        let(:args) { [loc_service_org, loc_case_storage, false, la1.vacols_id, la2.vacols_id] }

        it "moves one appeal to the new location and doesn't change the other" do
          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_transcription
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_service_org

          expect { subject }.to output(output_match).to_stdout

          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_transcription
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_case_storage
        end
      end

      context "an invalid vacols id is passed" do
        let(:invalid_id) { "invalid_vacols_id" }
        let(:output_match) { /No legacy appeal found for vacols_id #{invalid_id}; skipping./ }
        let(:args) { [loc_service_org, loc_case_storage, false, invalid_id, la1.vacols_id, la2.vacols_id] }

        it "notes the invalid id and moves the appeals to the new location" do
          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_service_org
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_service_org

          expect { subject }.to output(output_match).to_stdout

          expect(LegacyAppeal.find(la1.id).location_code).to eq loc_case_storage
          expect(LegacyAppeal.find(la2.id).location_code).to eq loc_case_storage
        end
      end

      context "fewer than three arguments are passed" do
        let(:args) { [loc_service_org, loc_case_storage] }
        let(:error_output) do
          "requires at least three arguments: a from location, a to location, and at least one VACOLS ID"
        end

        it "tells the caller that not enough argments were passed" do
          expect { subject }.to raise_error(NotEnoughArguments).with_message(error_output)
        end
      end

      context "no VACOLS IDs are passed" do
        let(:args) { [loc_service_org, loc_case_storage, false] }
        let(:error_output) do
          "you must pass VACOLS IDs for the appeals you want to change locations for"
        end

        it "tells the caller to include vacols IDs" do
          expect { subject }.to raise_error(NotEnoughArguments).with_message(error_output)
        end
      end

      context "an invalid VACOLS location is passed" do
        let(:invalid_location) { "NOT_A_REAL_LOCATION" }
        let(:args) { [loc_service_org, invalid_location, false, la1.vacols_id, la2.vacols_id] }
        let(:error_output) { "#{invalid_location} is not a valid VACOLS location" }

        it "alerts the user to the invalid location" do
          expect { subject }.to raise_error(InvalidLocationPassed).with_message(error_output)
        end
      end
    end
  end
end
