# frozen_string_literal: true

describe WorkQueue::NodDateUpdateSerializer, :postgres do
  let(:appeal) { create(:appeal) }
  let(:nod_date_update) { create(:nod_date_update) }
  subject { described_class.new(nod_date_update) }

  describe "#as_json" do
    it "renders for client consumption" do
      serializable_hash = {
        id: nod_date_update.id.to_s,
        type: :nod_date_update,
        attributes: {
          old_date: nod_date_update.old_date,
          new_date: nod_date_update.new_date,
          change_reason: nod_date_update.change_reason,
          updated_at: nod_date_update.updated_at,
          updated_by: nod_date_update.user.full_name
        }
      }
      expect(subject.serializable_hash[:data]).to eq(serializable_hash)
    end
  end
end
