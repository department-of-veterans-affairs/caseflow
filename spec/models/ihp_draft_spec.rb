# frozen_string_literal: true

describe IhpDraft do
  context "#create!" do
    let(:organization) { create(:organization) }
    let(:appeal) { create(:appeal) }
    let(:path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }

    let(:params) do
      {
        appeal: appeal,
        organization: organization,
        path: path
      }
    end

    subject { IhpDraft.new(params) }

    context "when appeal is not specified" do
      let(:appeal) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:appeal)).to be true
      end
    end

    context "when organization is not specified" do
      let(:organization) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:organization)).to be true
      end
    end

    context "when path is not specified" do
      let(:path) { nil }

      it "fails validation" do
        expect(subject.valid?).to be false
        expect(subject.errors.key?(:path)).to be true
      end
    end

    context "when path is invalid" do
      shared_examples "invalid path" do
        it "fails path regex validation" do
          expect(subject.valid?).to be false
          expect(subject.errors.key?(:path)).to be true
          expect(subject.errors[:path].first).to eq COPY::INVALID_IHP_DRAFT_PATH
        end
      end

      context "due to the wrong extension" do
        let(:params) { { appeal: appeal, organization: organization, path: path.gsub(".pdf", ".wrong") } }

        it_behaves_like "invalid path"
      end

      context "due to the wrong appeal_type" do
        let(:params) { { appeal: appeal, organization: organization, path: path.gsub("AMA IHPs", "902") } }

        it_behaves_like "invalid path"
      end

      context "due to not containing the beginning of the path" do
        let(:path) { "AML\\AMA IHPs\\VetName 12345.pdf" }

        it_behaves_like "invalid path"
      end

      context "due to only stipulating the V drive" do
        let(:path) { "V:\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }

        it_behaves_like "invalid path"
      end
    end

    context "When all params are valid" do
      it "successfully creates the record" do
        expect(subject.valid?).to be true
        expect(subject.save!).to be true
      end
    end
  end
end
