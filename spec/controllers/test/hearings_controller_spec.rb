# frozen_string_literal: true

describe Test::HearingsController, :postgres, type: :controller do
  describe "#index" do
    let(:css_id) { "VACOUSER" }
    let(:email) { "user@example.com" }
    let!(:user) { create(:user, css_id: css_id, email: email) }

    before do
      User.authenticate!(user: user)
    end

    context "user is not a Global Admin" do
      it "responds unauthorized" do
        get :index
        expect(response).to redirect_to "/unauthorized"
      end
    end

    context "user is Global Admin" do
      before do
        allow(user).to receive(:global_admin?) { true }
      end

      it "responds ok" do
        get :index
        expect(response.status).to eq 200
      end

      context "there are hearings" do
        let(:ama_hearing) { create(:hearing, regional_office: "RO43") }
        let(:hearing_task1) { create(:hearing_task, appeal: ama_hearing.appeal) }
        let!(:association1) { create(:hearing_task_association, hearing: ama_hearing, hearing_task: hearing_task1) }
        let!(:disposition_task1) do
          create(:assign_hearing_disposition_task, parent: hearing_task1)
        end

        let(:legacy_hearing1) { create(:legacy_hearing, regional_office: "RO43") }
        let(:hearing_task2) { create(:hearing_task, appeal: legacy_hearing1.appeal) }
        let!(:association2) { create(:hearing_task_association, hearing: legacy_hearing1, hearing_task: hearing_task2) }
        let!(:disposition_task2) do
          create(:assign_hearing_disposition_task, parent: hearing_task2)
        end

        let(:legacy_hearing2) { create(:legacy_hearing, regional_office: "RO43") }
        let(:hearing_task3) { create(:hearing_task, appeal: legacy_hearing2.appeal) }
        let!(:association3) { create(:hearing_task_association, hearing: legacy_hearing2, hearing_task: hearing_task3) }
        let!(:disposition_task3) do
          create(:assign_hearing_disposition_task, parent: hearing_task3)
        end

        it "responds with hearings profile information" do
          after = Time.zone.now - 1.week
          get :index, params: { after_year: after.year, after_month: after.month, after_day: after.day }
          json_body = JSON.parse response.body
          expect(json_body["profile"]["current_user_css_id"]).to eq css_id
          expect(json_body["hearings"]["ama_hearings"].count).to eq 1
          expect(json_body["hearings"]["legacy_hearings"].count).to eq 2
        end
      end

      context "the send_email parameter is passed" do
        context "the send_email parameter is 'true'" do
          it "attempts to send an email" do
            expect(Test::HearingsProfileJob).to receive(:perform_later).once.with(current_user)
            get :index, params: { send_email: "true" }
            json_body = JSON.parse response.body
            expect(json_body["email"]["email_sent"]).to eq true
            expect(json_body["email"]["email_address"]).to eq email
          end
        end

        context "the send_email paramater is something other than 'true'" do
          it "doesn't attempt to send an email" do
            expect(Test::HearingsProfileJob).to_not receive(:perform_later)
            get :index, params: { send_email: "something_else" }
            json_body = JSON.parse response.body
            expect(json_body["email"]["email_sent"]).to eq false
          end
        end
      end

      context "the after date parameters are passed" do
        let(:after) { Time.zone.local(2020, 11, 8) }

        it "sends the date to HearingsProfileHelper" do
          expect(Test::HearingsProfileHelper)
            .to receive(:profile_data)
            .once.with(current_user, after: after)
            .and_return({})
          get :index, params: { after_year: after.year, after_month: after.month, after_day: after.day }
        end
      end

      context "the limit parameter is passed" do
        it "sends the limit to HearingsProfileHelper" do
          expect(Test::HearingsProfileHelper)
            .to receive(:profile_data)
            .once.with(current_user, limit: 100)
            .and_return({})
          get :index, params: { limit: "100" }
        end
      end

      context "the include_eastern parameter is passed" do
        it "sends include_eastern to HearingsProfileHelper" do
          expect(Test::HearingsProfileHelper)
            .to receive(:profile_data)
            .once.with(current_user, include_eastern: true)
            .and_return({})
          get :index, params: { include_eastern: "true" }
        end
      end
    end
  end
end
