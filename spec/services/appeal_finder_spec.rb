# frozen_string_literal: true

describe AppealFinder, :all_dbs do
  let(:veteran) { legacy_appeal.veteran }
  let!(:appeal) { create(:appeal, veteran: veteran) }
  let(:unknown_docket_number) { "012345-000" }
  let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
  let(:invalid_docket_number) { "invaliddocket-number" }
  let!(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let(:second_appeal) { create(:appeal, veteran: veteran, stream_docket_number: appeal.stream_docket_number) }

  describe ".find_appeals_by_docket_number" do
    subject { described_class.find_appeals_by_docket_number(docket_number) }

    context "valid docket number" do
      let(:docket_number) { appeal.docket_number }

      it "returns only the matching appeal" do
        expect(subject.count).to eq(1)
        expect(subject.first.id).to eq(appeal.id)
      end
    end

    context "docket number cannot be found" do
      let(:docket_number) { unknown_docket_number }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "stream docket number matches two appeals" do
      let(:docket_number) { second_appeal.stream_docket_number }

      it "returns two appeals" do
        expect(subject.count).to eq(2)
        expect(subject.first.id).to eq(appeal.id)
        expect(subject.second.id).to eq(second_appeal.id)
        expect(subject.first.id).to_not eq(subject.second.id)
        expect(subject.second.stream_docket_number).to eq(subject.first.stream_docket_number)
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

    context "when the veteran has cancelled appeals" do
      let!(:cancelled_appeal) { create(:appeal, :assigned_to_judge, :cancelled, veteran: veteran) }
      let(:file_number) { appeal.veteran_file_number }

      it "returns the cancelled appeals" do
        results = subject

        expect(results.count).to eq(3)
        expect(results.map(&:id)).to contain_exactly(cancelled_appeal.id, appeal.id, legacy_appeal.id)
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
