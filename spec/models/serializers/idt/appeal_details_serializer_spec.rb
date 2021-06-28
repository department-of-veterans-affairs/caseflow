# frozen_string_literal: true

describe Idt::V1::AppealDetailsSerializer, :postgres do
  let(:appeal) { create(:appeal, veteran_is_not_claimant: true) }
  let(:include_addresses) { true }
  let(:base_url) { "va.gov" }
  let(:params) { { include_addresses: include_addresses, base_url: base_url } }

  subject { described_class.new(appeal, params: params) }

  context "Appellant data" do
    it "includes address_line_3" do
      serialized_attributes = subject.serializable_hash[:data][:attributes]
      claimant_attributes = serialized_attributes[:appellants].first
      expect(claimant_attributes[:address][:address_line_3]).to_not be nil
    end

    it "does not populate full_name when last name is present" do
      serialized_attributes = subject.serializable_hash[:data][:attributes]
      claimant_attributes = serialized_attributes[:appellants].first

      expect(claimant_attributes[:last_name]).to_not be nil
      expect(claimant_attributes[:full_name]).to be nil
    end

    context "when the claimant is missing last name, but has full name" do
      it "populates full name in appellant attributes" do
        allow_any_instance_of(Claimant).to receive(:name).and_return("Full Name")
        allow_any_instance_of(Claimant).to receive(:last_name).and_return(nil)

        serialized_attributes = subject.serializable_hash[:data][:attributes]
        claimant_attributes = serialized_attributes[:appellants].first

        expect(claimant_attributes[:last_name]).to be nil
        expect(claimant_attributes[:full_name]).to eq "Full Name".upcase
      end
    end
  end
end
