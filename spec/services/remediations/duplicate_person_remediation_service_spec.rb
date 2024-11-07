# frozen_string_literal: true

RSpec.describe Remediations::DuplicatePersonRemediationService, type: :service do
  let(:updated_person) { create(:person) }
  let(:duplicate_person_1) { create(:person) }
  let(:duplicate_person_2) { create(:person) }

  let(:duplicate_person_ids) { [duplicate_person_1.id, duplicate_person_2.id] }
  let(:dup_person_service) { described_class.new(updated_person_id: updated_person.id, duplicate_person_ids: duplicate_person_ids) }

  describe "#remediate!" do
    it "calls the find_and_update_records method to find and update records" do
      expect(dup_person_service).to receive(:find_and_update_records)
      dup_person_service.remediate!
    end
  end
end
