# frozen_string_literal: true

describe AppealFinder, :all_dbs do
  let(:veteran) { legacy_appeal.veteran }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let(:unknown_docket_number) { "012345-000" }
  let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
  let(:invalid_docket_number) { "invaliddocket-number" }
  let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }

  describe ".find_appeal_by_docket_number" do
    subject { described_class.find_appeal_by_docket_number(docket_number) }

    context "valid docket number" do
      let(:docket_number) { appeal.docket_number }

      it "returns results upon valid input" do
        expect(subject.id).to eq(appeal.id)
      end
    end

    context "docket number is invalid format" do
      let(:docket_number) { invalid_docket_number }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "docket number cannot be found" do
      let(:docket_number) { unknown_docket_number }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".find_appeals_with_file_numbers" do
    subject { described_class.find_appeals_with_file_numbers(file_number) }

    context "valid file number" do
      let(:file_number) { appeal.veteran_file_number }

      it "returns results" do
        results = subject

        expect(results.count).to eq(2)
        expect(results.map(&:id)).to contain_exactly(appeal.id, legacy_appeal.id)
      end
    end

    context "invalid file number" do
      let(:file_number) { invalid_veteran_id }

      it "returns empty array" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#find_appeals_for_veterans" do
    subject { described_class.new(user: user).find_appeals_for_veterans([veteran]) }

    context "user is non-VSO" do
      let(:user) { create(:user) }

      it "returns all appeals" do
        expect(subject.count).to eq(2)
      end
    end

    context "user is VSO" do
      let(:user) { create(:user, :vso_role, css_id: "BVA_VSO") }

      it "filters out appeals w/o access" do
        expect(subject).to be_empty
      end
    end
  end
end
