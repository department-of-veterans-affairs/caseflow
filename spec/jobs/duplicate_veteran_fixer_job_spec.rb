# frozen_string_literal: true

require_relative "../lib/helpers/shared/veterans_context"

describe DuplicateVeteranFixerJob, :postgres do
  include_context "veterans"

  it_behaves_like "a Master Scheduler serializable object", DuplicateVeteranFixerJob

  describe "#perform" do
    subject { DuplicateVeteranFixerJob.new }
    before do
      allow_any_instance_of(DuplicateVeteranFixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
    end

    it "removes error from supplemental_claim" do
      expect do
        subject.perform
        v1_supplemental_claims.reload
      end.to change { v1_supplemental_claims.establishment_error }.to(nil)
    end

    it "deletes duplicate veteran record" do
      expect { subject.perform }.to change { Veteran.count }.by(-1)
    end
  end
end
