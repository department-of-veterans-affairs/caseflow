# frozen_string_literal: true

RSpec.describe CorrespondenceDocumentController, :all_dbs, type: :controller do
  let(:correspondence) { create(:correspondence, :with_single_doc) }
  let(:document) { correspondence.correspondence_documents.first }
  let(:current_user) { create(:user) }
  let(:mail_team) { InboundOpsTeam.singleton }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    mail_team.add_user(current_user)
    User.authenticate!(user: current_user)
  end

  describe "PATCH #update_document" do
    before { patch :update_document, params: { id: document.id, vbms_document_type_id: 15 } }

    it "updates document given vbms_document_type_id param" do
      expect(response).to have_http_status(:ok)
      expect(document.reload.vbms_document_type_id).to eq(15)
    end
  end
end
