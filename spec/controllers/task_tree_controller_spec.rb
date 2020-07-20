# frozen_string_literal: true

describe TaskTreeController, :all_dbs, type: :controller do
  include TaskHelpers

  describe "GET task_tree/:appeal_type/:appeal_id" do
    let(:appeal) { create_legacy_appeal_with_hearings }

    before do
      User.authenticate!(roles: ["System Admin"])
    end

    before { FeatureToggle.enable!(:appeal_viz) }
    after { FeatureToggle.disable!(:appeal_viz) }

    context ".json request" do
      subject { get :show, params: { appeal_type: appeal.class.name, appeal_id: appeal.vacols_id }, as: :json }

      it "returns valid JSON tree" do
        subject
        task_tree = JSON.parse(response.body)["task_tree"]

        expect(task_tree["LegacyAppeal"]["tasks"]).to be_a Array
      end
    end

    context ".txt request" do
      subject { get :show, params: { appeal_type: appeal.class.name, appeal_id: appeal.vacols_id }, as: :text }

      it "returns plain text tree" do
        subject
        task_tree = response.body

        expect(task_tree).to match(/LegacyAppeal #{appeal.id}/)
      end
    end

    context ".html (default) request" do
      subject { get :show, params: { appeal_type: appeal.class.name, appeal_id: appeal.vacols_id }, as: :html }

      it "returns dynamic HTML tree" do
        subject

        expect(response).to be_ok
      end
    end
  end
end
