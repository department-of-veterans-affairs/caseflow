# frozen_string_literal: true

describe SavedSearchSerializer, :postgres do
  describe "#as_json" do
    let(:user) { create(:user, :vha_admin_user) }
    let(:saved_search) do
      create(
        :saved_search,
        user: user,
        name: "my_first_search",
        description: "my first search",
        saved_search: "{report_type: 'event_type_action'}"
      )
    end

    subject { described_class.new(saved_search) }

    it "renders saved search data" do
      serializable_hash = {
        name: "my_first_search",
        description: "my first search",
        savedSearch: "{report_type: 'event_type_action'}",
        createdAt: saved_search.created_at,
        userCssId: user.css_id,
        userFullName: user.full_name,
        userId: user.id
      }
      expect(subject.serializable_hash[:data][:attributes]).to eq(serializable_hash)
    end
  end
end
