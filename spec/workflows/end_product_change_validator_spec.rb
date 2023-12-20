# frozen_string_literal: true

describe EndProductChangeValidator do
  describe "#eligible_new_codes_hash" do
    subject { EndProductChangeValidator.eligible_new_codes_hash(code) }

    context "when original code is in the 040 family" do
      let(:code) { "040SCNRPMC" }

      it "allows changes only to other 040 codes" do
        expect(subject.values).to all include(family: "040")
      end
    end

    context "when original code is for an HLR" do
      let(:code) { "030HLRR" }

      it "allows changes only to other HLR codes" do
        expect(subject.values).to all include(review_type: "higher_level_review")
      end
    end

    context "when original code is for fiduciary benefit type" do
      let(:code) { "040SCRFID" }

      it "allows no changes" do
        expect(subject).to be_empty
      end
    end

    context "when original code is for a remand" do
      let(:code) { "040BDENR" }

      it "allows changes only to other remand codes" do
        expect(subject.values).to all include(disposition_type: "board_remand")
      end
    end

    context "when original code is for a remand" do
      let(:code) { "030BGR" }

      it "allows changes only to other BGE codes" do
        expect(subject.values).to all include(disposition_type: "allowed")
      end
    end

    context "when original code is for a DTA claim" do
      let(:code) { "040HDENR" }

      it "allows changes only to other DTA codes" do
        expect(subject.values).to all include(disposition_type: "dta_error")
      end
    end

    context "when original code is for a DOO claim" do
      let(:code) { "930AHNRCPMC" }

      it "allows changes only to other DOO codes" do
        expect(subject.values).to all include(disposition_type: "difference_of_opinion")
      end
    end
  end
end
