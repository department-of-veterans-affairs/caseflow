# frozen_string_literal: true

require "support/api_helpers"

describe Api::V2::Appeals, :all_dbs do
  include ApiHelpers

  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  before do
    api_setup_appeal_repository_dockets
  end

  describe "#to_hash" do
    context "Legacy Appeal list" do
      before do
        DocketSnapshot.create
      end

      let(:ssn) { "111223333" }
      let(:vbms_id) { "111223333S" }

      let!(:original) { api_create_legacy_appeal_complete_with_hearings(vbms_id) }
      let!(:post_remand) { api_create_legacy_appeal_post_remand(vbms_id) }
      let!(:another_original) { api_create_legacy_appeal_advance(vbms_id) }

      let!(:another_veteran_appeal) do
        create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "333222333S"))
      end

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_file_number_by_ssn) do |_bgs, ssn|
          ssn
        end
      end

      subject { Api::V2::Appeals.new(veteran_file_number: ssn, vbms_id: vbms_id).to_hash }

      it "returns hash of legacy appeals" do
        resp = subject

        expect(resp[:data].count).to eq(2)
      end
    end
  end
end
