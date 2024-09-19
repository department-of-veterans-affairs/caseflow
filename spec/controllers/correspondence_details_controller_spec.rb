# frozen_string_literal: true

require "rails_helper"

RSpec.describe CorrespondenceDetailsController, :all_dbs, type: :controller do
  describe "GET #correspondence_details" do
    let!(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:veteran) { create(:veteran) }
    let!(:correspondence) { create(:correspondence, :with_correspondence_intake_task, assigned_to: current_user) }

    before :each do
      Fakes::Initializer.load!
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
      InboundOpsTeam.singleton.add_user(current_user)
      correspondence.update(veteran: veteran)
      correspondence.tasks.update(status: :completed)
    end

    context "when format is HTML" do
      it "responds successfully with an HTTP 200 status code" do
        get :correspondence_details, params: { correspondence_uuid: correspondence.uuid }, format: :html
        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
      end
    end

    context "when format is JSON" do
      it "renders the correspondence details as JSON" do
        get :correspondence_details, params: { correspondence_uuid: correspondence.uuid }, format: :json
        json = JSON.parse(response.body)
        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
        expect(json["correspondence"]).to be_present
        expect(json["correspondence"]["appeals_information"]).to be_present
        expect(json["correspondence"]["all_correspondences"]).to be_present
      end
    end
  end

  describe "POST #create_correspondence_relations" do
    let!(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:veteran) { create(:veteran) }
    let!(:correspondence) { create(:correspondence, :with_correspondence_intake_task, assigned_to: current_user) }
    let(:prior_mail_ids) { [1, 2, 3] }

    before do
      allow(CorrespondenceRelation).to receive(:create!)
      allow(Correspondence).to receive(:find).and_return(correspondence)
    end

    describe "POST #create_correspondence_relations" do
      context "with valid priorMailIds" do
        it "creates the correspondence relations" do
          post :create_correspondence_relations, params: {
            correspondence_uuid: correspondence.uuid,
            priorMailIds: prior_mail_ids
          }

          expect(CorrespondenceRelation).to have_received(:create!).exactly(prior_mail_ids.size).times
          prior_mail_ids.each do |corr_id|
            expect(CorrespondenceRelation).to have_received(:create!).with(
              correspondence_id: corr_id,
              related_correspondence_id: correspondence.id
            )
          end
        end
      end

      context "when priorMailIds is empty" do
        it "does not create any correspondence relations" do
          post :create_correspondence_relations, params: { correspondence_uuid: correspondence.uuid, priorMailIds: [] }

          expect(CorrespondenceRelation).not_to have_received(:create!)
        end
      end

      context "when priorMailIds is missing" do
        it "does not create any correspondence relations" do
          post :create_correspondence_relations, params: { correspondence_uuid: correspondence.uuid }

          expect(CorrespondenceRelation).not_to have_received(:create!)
        end
      end

      context "when CorrespondenceRelation creation raises an error" do
        before do
          allow(CorrespondenceRelation).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "raises an error and does not create any relations" do
          expect do
            post :create_correspondence_relations, params: {
              correspondence_uuid: correspondence.uuid,
              priorMailIds: prior_mail_ids
            }
          end.to raise_error(ActiveRecord::RecordInvalid)

          expect(CorrespondenceRelation).to have_received(:create!).once
        end
      end
    end
  end
end
