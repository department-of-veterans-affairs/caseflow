# frozen_string_literal: true

describe Test::CorrespondenceController, :postgres, type: :controller do
  let!(:user) { create(:user) }

  before do
    User.authenticate!(user: user)

    (1..15).each do |i|
      create(:correspondence_type, id: i, name: "Type #{i}")
    end
  end
  describe "GET #index" do
    context "when user has access" do
      before do
        allow(user).to receive(:admin?).and_return(true)
        allow(controller).to receive(:access_allowed?).and_return(true)
        allow(controller).to receive(:verify_access).and_return(true)
        allow(controller).to receive(:verify_feature_toggle).and_return(true)
      end

      it "renders the index template" do
        get :index
        expect(response.status).to eq 200
      end
    end

    context "when user does not have access" do
      before do
        allow(user).to receive(:admin?).and_return(false)
        allow(controller).to receive(:access_allowed?).and_return(false)
        allow(controller).to receive(:verify_access).and_call_original
      end

      it "redirects to unauthorized path" do
        get :index
        expect(response).to redirect_to("/unauthorized")
      end
    end

    context "when feature toggle is disabled" do
      before do
        allow(user).to receive(:admin?).and_return(true)
        allow(controller).to receive(:access_allowed?).and_return(true)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_queue).and_return(false)
        allow(controller).to receive(:verify_access).and_return(true)
      end

      it "redirects to under construction path" do
        get :index
        expect(response.status).to eq(302)
      end
    end

    context "when feature toggle and user access are disabled" do
      before do
        allow(user).to receive(:admin?).and_return(false)
        allow(controller).to receive(:access_allowed?).and_return(false)
        allow(controller).to receive(:verify_access).and_return(false)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_queue).and_return(false)
        allow(controller).to receive(:feature_enabled?).with(:correspondence_admin).and_return(true)
      end

      it "redirects to unauthorized path" do
        get :index
        expect(response).to redirect_to("/unauthorized")
      end
    end
  end

  describe "POST #generate_correspondence" do
    let(:params) { { file_numbers: "123456789,987654321", count: 2 } }
    let(:valid_veterans) { ["123456789"] }
    let(:invalid_veterans) { ["987654321"] }

    before do
      allow(controller).to receive(:classify_file_numbers).and_return(
        { valid: valid_veterans, invalid: invalid_veterans }
      )
      allow(controller).to receive(:connect_corr_with_vet)
    end

    it "classifies file numbers" do
      post :generate_correspondence, params: params

      expect(controller).to have_received(:classify_file_numbers).with(%w[123456789 987654321])
    end

    it "connects correspondences with valid veterans" do
      post :generate_correspondence, params: params

      expect(controller).to have_received(:connect_corr_with_vet).with(valid_veterans, 2)
    end

    it "returns valid and invalid file numbers in response" do
      post :generate_correspondence, params: params

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response["valid_file_nums"]).to eq(valid_veterans)
      expect(json_response["invalid_file_numbers"]).to eq(invalid_veterans)
    end
  end

  describe "private methods" do
    describe "#verify_access" do
      context "when user is an admin" do
        before do
          allow(user).to receive(:admin?).and_return(true)
        end

        it "returns true" do
          expect(controller.send(:verify_access)).to be true
        end
      end
    end

    describe "#bva?" do
      it "checks user access for BVA roles" do
        Bva.singleton.add_user(current_user)
        expect(controller.send(:bva?)).to be true
      end
    end

    describe "#access_allowed?" do
      context "in UAT environment" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
          allow(Rails).to receive(:deploy_env?).with(:demo).and_return(false)
        end

        it "returns true" do
          expect(controller.send(:access_allowed?)).to be true
        end
      end

      context "in demo environment" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(false)
          allow(Rails).to receive(:deploy_env?).with(:demo).and_return(true)
        end

        it "returns true" do
          expect(controller.send(:access_allowed?)).to be true
        end
      end
    end

    describe "#connect_corr_with_vet" do
      let!(:valid_veterans) { create_list(:veteran, 3) }
      let(:valid_file_nums) { valid_veterans.map(&:file_number) }
      let(:user) { create(:user) }
      let(:count) { 2 }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "creates correspondences and associated documents for each valid file number" do
        expect do
          controller.send(:connect_corr_with_vet, valid_file_nums, count)
        end.to change(Correspondence, :count).by(valid_file_nums.size * count)
          .and change(CorrespondenceDocument, :count)

        valid_veterans.each do |veteran|
          veteran.reload
          veteran.correspondences.each do |correspondence|
            expect(correspondence.va_date_of_receipt).to be_between(90.days.ago.to_date, Date.yesterday)
            expect(correspondence.notes).to eq("This is a test note")
            expect(correspondence.correspondence_documents.size).to be_between(1, 5).inclusive
          end
        end
      end

      it "assigns NOD document types correctly" do
        controller.send(:connect_corr_with_vet, valid_file_nums, count)

        valid_veterans.each do |veteran|
          veteran.reload
          veteran.correspondences.where(nod: true).find_each do |correspondence|
            expect(correspondence.correspondence_documents.last.document_type).to eq(1250)
            expect(correspondence.correspondence_documents.last.vbms_document_type_id).to eq(1250)
          end
        end
      end

      it "creates a BatchAutoAssignmentAttempt and enqueues AutoAssignCorrespondenceJob" do
        expect do
          controller.send(:connect_corr_with_vet, valid_file_nums, count)
        end.to change(BatchAutoAssignmentAttempt, :count).by(1)

        batch = BatchAutoAssignmentAttempt.last
        expect(batch.user).to eq(user)
      end
    end

    describe "#classify_file_numbers" do
      let(:file_numbers) { %w[123456789 987654321 111222333] }

      before do
        allow(controller).to receive(:valid_veteran?).with("123456789").and_return(true)
        allow(controller).to receive(:valid_veteran?).with("987654321").and_return(false)
        allow(controller).to receive(:valid_veteran?).with("111222333").and_return(true)
      end

      it "classifies file numbers into valid and invalid arrays" do
        result = controller.send(:classify_file_numbers, file_numbers)
        expect(result[:valid]).to contain_exactly("123456789", "111222333")
        expect(result[:invalid]).to contain_exactly("987654321")
      end
    end

    describe "#valid_veteran?" do
      let(:file_number) { "123456789" }
      let(:veteran) { create(:veteran, file_number: file_number) }

      context "when in UAT environment" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
        end

        it "returns true if veteran is found in UAT" do
          allow(VeteranFinder).to receive(:find_best_match).with(file_number).and_return(veteran)
          allow(veteran).to receive(:fetch_bgs_record).and_return(true)

          expect(controller.send(:valid_veteran?, file_number)).to be_truthy
        end
      end

      context "when in other environments" do
        before do
          allow(Rails).to receive(:deploy_env?).with(:uat).and_return(false)
        end

        it "returns true if veteran is found in database" do
          allow(Veteran).to receive(:find_by).with(file_number: file_number).and_return(veteran)

          expect(controller.send(:valid_veteran?, file_number)).to be_truthy
        end
      end
    end
  end
end
