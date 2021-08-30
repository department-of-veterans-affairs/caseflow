# frozen_string_literal: true

RSpec.describe Idt::Api::V1::AppealsController, type: :controller do
  describe "GET /idt/api/v1/appeals", :all_dbs do
    let(:user) { create(:user, css_id: "TEST_ID", full_name: "George Michael") }
    let(:token) do
      key, token = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      token
    end

    it_behaves_like "IDT access verification", :get, :list

    context "when request header contains valid token" do
      context "and user is a judge" do
        let(:role) { :judge_role }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        let!(:appeals) do
          [
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user)),
            create(:legacy_appeal, vacols_case: create(:case, :assigned, user: user))
          ]
        end

        let(:veteran1) { create(:veteran) }
        let(:veteran2) { create(:veteran) }

        let!(:ama_appeals) do
          [
            create(:appeal, veteran: veteran1, number_of_claimants: 1),
            create(:appeal, veteran: veteran2, number_of_claimants: 1)
          ]
        end

        let!(:tasks) do
          [
            create(:ama_judge_assign_task, assigned_to: user, appeal: ama_appeals.first),
            create(:ama_judge_decision_review_task, assigned_to: user, appeal: ama_appeals.second)
          ]
        end

        it "returns a list of assigned appeals" do
          get :list
          expect(response.status).to eq 200
          expect(RequestStore[:current_user]).to eq user
          response_body = JSON.parse(response.body)["data"]
          ama_appeals = response_body
            .select { |appeal| appeal["attributes"]["type"] == "Appeal" }
            .sort_by { |appeal| appeal["attributes"]["file_number"] }

          expect(ama_appeals.size).to eq 1
          expect(ama_appeals.first["id"]).to eq tasks.second.appeal.uuid
          expect(ama_appeals.first["attributes"]["docket_number"]).to eq tasks.second.appeal.docket_number
          expect(ama_appeals.first["attributes"]["veteran_first_name"]).to eq veteran2.reload.name.first_name
        end
      end

      context "and user is a mail intake" do
        let(:user) { User.find_by_css_id("ID1234") }
        before do
          User.authenticate!(roles: ["Mail Intake"], css_id: "ID1234")
          request.headers["TOKEN"] = token
        end

        it "returns an empty list" do
          get :list
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["data"]
          # Intake users don't have any appeals assigned to them
          expect(response_body).to eq []
        end
      end

      context "and the user is intake" do
        let(:user) { User.find_by_css_id("ID1234") }
        let(:appeal) { create(:appeal, number_of_claimants: 1) }
        let(:params) { { appeal_id: appeal.uuid } }

        before do
          User.authenticate!(roles: ["Mail Intake"], css_id: "ID1234")
          request.headers["TOKEN"] = token
          allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_return(
            address_line_1: "1234 K St.",
            address_line_2: "APT 3",
            address_line_3: "",
            city: "Washington",
            country: "USA",
            state: "CA",
            zip: "20001"
          )
        end

        it "succeeds and passes address info" do
          get :details, params: params
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["data"]

          expect(response_body["attributes"]["appellants"][0]["address"]["address_line_1"])
            .to eq appeal.claimant.address_line_1
          expect(response_body["attributes"]["appellants"][0]["address"]["city"])
            .to eq appeal.claimant.city
          expect(response_body["attributes"]["appellants"][0]["representative"]["address"])
            .to eq appeal.representative_address.stringify_keys
        end
      end

      context "and user is an attorney" do
        let(:role) { :attorney_role }

        before do
          create(:staff, role, sdomainid: user.css_id)
          request.headers["TOKEN"] = token
        end

        let(:assigner1) { create(:user, css_id: "ANOTHER_TEST_ID1", full_name: "Lyor Cohen") }
        let(:assigner2) { create(:user, css_id: "ANOTHER_TEST_ID2", full_name: "Grey White") }

        let(:vacols_case1) do
          create(:case,
                 :status_active,
                 :assigned,
                 user: user,
                 assigner: assigner1,
                 decass_count: 2,
                 document_id: "1234",
                 bfdloout: 2.days.ago.to_date)
        end
        let(:vacols_case2) do
          create(:case,
                 :status_active,
                 :assigned,
                 user: user,
                 assigner: assigner2,
                 document_id: "5678",
                 bfdloout: 4.days.ago.to_date)
        end

        let!(:appeals) do
          [
            create(:legacy_appeal, vacols_case: vacols_case1),
            create(:legacy_appeal, vacols_case: vacols_case2)
          ]
        end

        let(:veteran1) { create(:veteran) }
        let(:veteran2) { create(:veteran) }

        let!(:ama_appeals) do
          [
            create(:appeal, veteran: veteran1, number_of_claimants: 1, veteran_is_not_claimant: true),
            create(:appeal, veteran: veteran2, number_of_claimants: 1),
            create(:appeal, veteran: veteran1, number_of_claimants: 1)
          ].map { |appeal| appeal.tap(&:create_tasks_on_intake_success!) }
        end

        let!(:parents) do
          [
            create(:ama_judge_decision_review_task, appeal: ama_appeals.first, parent: ama_appeals.first.root_task),
            create(:ama_judge_decision_review_task, appeal: ama_appeals.second, parent: ama_appeals.second.root_task),
            create(:ama_judge_decision_review_task, appeal: ama_appeals.last, parent: ama_appeals.last.root_task)
          ]
        end

        let!(:tasks) do
          [
            create(:ama_attorney_task, assigned_to: user, parent: parents.first),
            create(:ama_attorney_task, assigned_to: user, parent: parents.second),
            create(:ama_attorney_task, assigned_to: user, parent: parents.last)
          ]
        end

        let!(:case_review1) do
          create(
            :attorney_case_review,
            created_at: Time.zone.now - 1.minute,
            updated_at: Time.zone.now - 1.minute,
            document_id: "17325093.1116",
            task_id: tasks.first.id
          )
        end
        let!(:case_review2) do
          create(
            :attorney_case_review,
            created_at: Time.zone.now,
            updated_at: Time.zone.now,
            document_id: "17325093.1117",
            task_id: tasks.first.id
          )
        end

        before do
          # cancel one, so it does not show up
          Appeal.where(veteran_file_number: veteran1.file_number).last.tasks.each(&:cancelled!)

          # mark all distribution tasks complete so status logic is consistent
          DistributionTask.all.each(&:completed!)
        end

        it "returns a list of active assigned appeals" do
          tasks.first.update(assigned_at: 5.days.ago)
          tasks.second.update(assigned_at: 15.days.ago)
          get :list
          expect(response.status).to eq 200
          expect(RequestStore[:current_user]).to eq user
          response_body = JSON.parse(response.body)["data"]
          ama_appeals = response_body
            .select { |appeal| appeal["attributes"]["type"] == "Appeal" }
            .sort_by { |appeal| appeal["attributes"]["file_number"] }

          expect(ama_appeals.size).to eq 2
          expect(ama_appeals.first["id"]).to eq tasks.first.appeal.uuid
          expect(ama_appeals.first["attributes"]["docket_number"]).to eq tasks.first.appeal.docket_number
          expect(ama_appeals.first["attributes"]["veteran_first_name"]).to eq veteran1.reload.name.first_name
          expect(ama_appeals.first["attributes"]["days_waiting"]).to eq 5

          expect(ama_appeals.second["id"]).to eq tasks.second.appeal.uuid
          expect(ama_appeals.second["attributes"]["docket_number"]).to eq tasks.second.appeal.docket_number
          expect(ama_appeals.second["attributes"]["veteran_first_name"]).to eq veteran2.reload.name.first_name
          expect(ama_appeals.second["attributes"]["days_waiting"]).to eq 15

          expect(ama_appeals.first["attributes"]["assigned_by"]).to eq tasks.first.parent.assigned_to.full_name
          expect(ama_appeals.first["attributes"]["documents"].size).to eq 2
          expect(ama_appeals.first["attributes"]["documents"].first["written_by"])
            .to eq case_review2.attorney.full_name
          expect(ama_appeals.first["attributes"]["documents"].first["document_id"])
            .to eq case_review2.document_id
          expect(ama_appeals.first["attributes"]["documents"].second["written_by"])
            .to eq case_review1.attorney.full_name
          expect(ama_appeals.first["attributes"]["documents"].second["document_id"])
            .to eq case_review1.document_id
        end

        it "returns active appeals associated with a file number" do
          headers = { "FILENUMBER" => veteran1.file_number }
          request.headers.merge! headers
          get :list
          expect(response.status).to eq 200
          response_body = JSON.parse(response.body)["data"]
          ama_appeals = response_body.select { |appeal| appeal["attributes"]["type"] == "Appeal" }
          expect(ama_appeals.size).to eq 1
          expect(ama_appeals.first["attributes"]["docket_number"]).to eq tasks.first.appeal.docket_number
          expect(ama_appeals.first["attributes"]["veteran_first_name"]).to eq veteran1.reload.name.first_name
          expect(ama_appeals.first["attributes"]["assigned_by"]).to eq tasks.first.parent.assigned_to.full_name
          expect(ama_appeals.first["attributes"]["documents"].size).to eq 2
        end

        context "and appeal id URL parameter not is passed" do
          it "succeeds" do
            get :list
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]
            expect(response_body.first["attributes"]["veteran_first_name"]).to eq appeals.first.veteran_first_name
            expect(response_body.first["attributes"]["veteran_last_name"]).to eq appeals.first.veteran_last_name
            expect(response_body.first["attributes"]["file_number"]).to eq appeals.first.veteran_file_number

            expect(response_body.second["attributes"]["veteran_first_name"]).to eq appeals.second.veteran_first_name
            expect(response_body.second["attributes"]["veteran_last_name"]).to eq appeals.second.veteran_last_name
            expect(response_body.second["attributes"]["file_number"]).to eq appeals.second.veteran_file_number

            expect(response_body.first["attributes"]["days_waiting"]).to eq 2
            expect(response_body.first["attributes"]["assigned_by"]).to eq "Lyor Cohen"
            expect(response_body.first["attributes"]["documents"].size).to eq 2
            expect(response_body.first["attributes"]["documents"].first["document_id"]).to eq "1234"
            expect(response_body.first["attributes"]["documents"].second["document_id"]).to eq "1234"

            expect(response_body.second["attributes"]["days_waiting"]).to eq 4
            expect(response_body.second["attributes"]["assigned_by"]).to eq "Grey White"
            expect(response_body.second["attributes"]["documents"].size).to eq 1
            expect(response_body.second["attributes"]["documents"].first["document_id"]).to eq "5678"
          end
        end

        context "an AMA appeal id URL parameter is passed" do
          let(:params) { { appeal_id: ama_appeals.first.uuid } }
          let!(:request_issue1) { create(:request_issue, decision_review: ama_appeals.first) }
          let!(:request_issue2) { create(:request_issue, decision_review: ama_appeals.first) }

          context "and addresses should not be queried" do
            before do
              expect_any_instance_of(Fakes::BGSService).to_not receive(:find_address_by_participant_id)
            end

            it "succeeds and passes appeal info" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              appeal = ama_appeals.first
              poa = appeal.claimant.power_of_attorney

              expect(response_body["attributes"]["case_details_url"])
                .to end_with "queue/appeals/#{appeal.external_id}"

              expect(response_body["attributes"]["veteran_first_name"]).to eq appeal.veteran_first_name
              expect(response_body["attributes"]["veteran_last_name"]).to eq appeal.veteran_last_name
              expect(response_body["attributes"]["veteran_name_suffix"]).to eq appeal.veteran.name_suffix
              expect(response_body["attributes"]["file_number"]).to eq appeal.veteran_file_number

              expect(response_body["attributes"]["representative_address"]).to eq(nil)
              expect(response_body["attributes"]["aod"]).to eq appeal.advanced_on_docket?
              expect(response_body["attributes"]["cavc"]).to eq false
              expect(response_body["attributes"]["issues"].first["program"]).to eq "Compensation"
              expect(response_body["attributes"]["issues"].second["program"]).to eq "Compensation"
              expect(response_body["attributes"]["status"]).to eq "assigned_to_attorney"
              expect(response_body["attributes"]["veteran_is_deceased"]).to eq false
              expect(response_body["attributes"]["veteran_ssn"]).to eq appeal.veteran_ssn
              expect(response_body["attributes"]["veteran_death_date"]).to eq nil
              expect(response_body["attributes"]["appellant_is_not_veteran"]).to eq true
              expect(response_body["attributes"]["appellants"][0]["first_name"]).to eq appeal.appellant_first_name
              expect(response_body["attributes"]["appellants"][0]["last_name"]).to eq appeal.appellant_last_name
              expect(response_body["attributes"]["appellants"][0]["representative"]["name"])
                .to eq poa.representative_name
              expect(response_body["attributes"]["appellants"][0]["representative"]["type"])
                .to eq poa.representative_type
            end
          end

          context "and the user is from dispatch" do
            let(:user) { create(:user) }

            before do
              BvaDispatch.singleton.add_user(user)
              allow_any_instance_of(Fakes::BGSService).to receive(:find_address_by_participant_id).and_return(
                address_line_1: "1234 K St.",
                address_line_2: "APT 3",
                address_line_3: "",
                city: "Washington",
                country: "USA",
                state: "CA",
                zip: "20001"
              )

              allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poas_by_participant_ids)
                .with([ama_appeals.first.claimant.participant_id]).and_return(
                  ama_appeals.first.claimant.participant_id => {
                    representative_name: "POA Name",
                    representative_type: "POA Attorney",
                    participant_id: "600153863"
                  }
                )
            end

            it "succeeds and passes address info" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["appellants"][0]["address"]["address_line_1"])
                .to eq ama_appeals.first.reload.claimant.address_line_1
              expect(response_body["attributes"]["appellants"][0]["address"]["city"])
                .to eq ama_appeals.first.claimant.city
              expect(response_body["attributes"]["appellants"][0]["representative"]["address"])
                .to eq ama_appeals.first.representative_address.stringify_keys
              expect(response_body["attributes"]["assigned_by"]).to_not eq nil
              expect(response_body["attributes"]["assigned_by"]).to eq tasks.first.parent.assigned_to.full_name
              expect(response_body["attributes"]["documents"].size).to eq 2
            end
          end
        end

        context "and appeal id URL parameter is not valid" do
          let(:params) { { appeal_id: "invalid" } }

          it "responds with not found" do
            get :details, params: params
            expect(response.status).to eq 404
          end
        end

        context "and legacy appeal id URL parameter is passed" do
          let(:params) { { appeal_id: appeal.vacols_id } }
          let!(:vacols_case) do
            create(:case, :assigned, correspondent: correspondent, user: user, bfso: "T")
          end
          let(:correspondent) do
            create(
              :correspondent,
              appellant_first_name: "Forrest",
              appellant_last_name: "Gump"
            )
          end
          let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

          it "succeeds and passes appeal info" do
            get :details, params: params
            expect(response.status).to eq 200
            response_body = JSON.parse(response.body)["data"]

            expect(response_body["attributes"]["case_details_url"]).to end_with "queue/appeals/#{appeal.external_id}"
            expect(response_body["attributes"]["veteran_first_name"]).to eq appeal.veteran_first_name
            expect(response_body["attributes"]["veteran_last_name"]).to eq appeal.veteran_last_name
            expect(response_body["attributes"]["veteran_name_suffix"]).to eq "PhD"
            expect(response_body["attributes"]["veteran_ssn"]).to eq appeal.veteran_ssn
            expect(response_body["attributes"]["file_number"]).to eq appeal.veteran_file_number
            # BGS service default attorney: Clarence Darrow
            expect(response_body["attributes"]["appellants"][0]["representative"]["name"]).to eq("Clarence Darrow")
            expect(response_body["attributes"]["appellants"][0]["first_name"]).to eq("Forrest")
            expect(response_body["attributes"]["aod"]).to eq appeal.aod
            expect(response_body["attributes"]["cavc"]).to eq appeal.cavc
            expect(response_body["attributes"]["issues"]).to eq appeal.issues
            expect(response_body["attributes"]["status"]).to eq appeal.status
            expect(response_body["attributes"]["veteran_is_deceased"]).to eq appeal.veteran_is_deceased
            expect(response_body["attributes"]["veteran_death_date"]).to eq appeal.veteran_death_date
            expect(response_body["attributes"]["appellant_is_not_veteran"]).to eq !!appeal.appellant_first_name
          end

          context "and BGS::AccountLocked error is raised" do
            let(:account_locked_error) { BGS::AccountLocked.new("Your account is locked.", 500) }
            before do
              allow(controller).to receive(:json_appeal_details).and_raise(account_locked_error)
            end

            it "responds with 403 Forbidden error" do
              get :details, params: params
              expect(response.status).to eq 403
              expect(JSON.parse(response.body)["message"])
                .to eq "Your account is locked. Please contact the VA Enterprise Service Desk to resolve this issue."
            end
          end

          # Unfortunately we need to make the contested claimant tests separate from the above since
          # instantiating multiple representative records is hard because there is a unique index
          # on the timestamp repaddtime. This timestamp is determined by the Oracle DB and so isn't
          # manipulable from TimeCop, nor is it settable from FactoryBot
          context "when contested claimant" do
            let!(:representative) do
              create(
                :representative,
                repkey: vacols_case.bfkey,
                reptype: "C",
                repfirst: "Contested",
                replast: "Claimant",
                repso: "A"
              )
            end

            it "returns contested claimant" do
              get :details, params: params
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["contested_claimants"][0]["first_name"]).to eq("Contested")
              expect(response_body["attributes"]["contested_claimants"][0]["representative"]["code"])
                .to eq(representative.repso)
              expect(response_body["attributes"]["contested_claimants"][0]["representative"]["name"])
                .to eq(VACOLS::Case::REPRESENTATIVES[representative.repso][:full_name])
            end
          end

          context "when contested claimant with unknown REPSO value (representative code)" do
            let!(:representative) do
              create(
                :representative,
                repkey: vacols_case.bfkey,
                reptype: "C",
                repfirst: "Contested",
                replast: "Claimant",
                repso: "5"
              )
            end

            it "returns nil value for representative name" do
              get :details, params: params
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["contested_claimants"][0]["first_name"]).to eq("Contested")
              expect(response_body["attributes"]["contested_claimants"][0]["representative"]["code"])
                .to eq representative.repso
              expect(response_body["attributes"]["contested_claimants"][0]["representative"]["name"])
                .to be_nil
            end
          end

          context "when contested claimant agent" do
            let!(:representative) do
              create(
                :representative,
                repkey: vacols_case.bfkey,
                reptype: "D",
                repfirst: "Contested Agent",
                replast: "Claimant"
              )
            end

            it "returns contested claimant" do
              get :details, params: params
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["contested_claimant_agents"][0]["first_name"]).to eq("Contested Agent")
            end
          end

          context "and case is selected for quality review and has outstanding mail" do
            let(:vacols_case) do
              create(:case,
                     :selected_for_quality_review,
                     :assigned,
                     user: user)
            end
            let(:appeal) do
              create(:legacy_appeal, vacols_case: vacols_case)
            end

            let!(:outstanding_mail) do
              [
                create(:mail, mlfolder: vacols_case.bfkey, mltype: "02"),
                create(:mail, mlfolder: vacols_case.bfkey, mltype: "05")
              ]
            end

            it "returns the correct values for the appeal" do
              get :details, params: params
              expect(response.status).to eq 200
              response_body = JSON.parse(response.body)["data"]

              expect(response_body["attributes"]["previously_selected_for_quality_review"]).to eq true
              expect(response_body["attributes"]["outstanding_mail"]).to eq [
                { "outstanding" => false, "code" => "02", "description" => "Congressional Interest" },
                { "outstanding" => true, "code" => "05", "description" => "Evidence or Argument" }
              ]
            end
          end
        end
      end
    end
  end

  describe "POST /idt/api/v1/appeals/:appeal_id/outcode", :postgres do
    let(:user) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:citation_number) { "A18123456" }
    let(:params) do
      { appeal_id: root_task.appeal.external_id,
        citation_number: citation_number,
        decision_date: Date.new(1989, 12, 13).to_s,
        file: "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW",
        redacted_document_location: "C://Windows/User/BLOBLAW/Documents/Decision.docx" }
    end

    before do
      allow(controller).to receive(:verify_access).and_return(true)
      BvaDispatch.singleton.add_user(user)

      key, t = Idt::Token.generate_one_time_key_and_proposed_token
      Idt::Token.activate_proposed_token(key, user.css_id)
      request.headers["TOKEN"] = t
    end

    context "when some params are missing" do
      let(:params) { { appeal_id: root_task.appeal.external_id, citation_number: citation_number } }
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "should throw an error" do
        post :outcode, params: params
        error_message = "Decision date can't be blank, Redacted document " \
                        "location can't be blank, File can't be blank"

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq error_message
      end
    end

    context "when citation_number parameter fails validation" do
      let(:citation_number) { "INVALID" }
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq "Citation number is invalid"
      end
    end

    context "when citation_number already exists on a different appeal" do
      before do
        BvaDispatchTask.create_from_root_task(root_task)
        create(:decision_document, citation_number: citation_number, appeal: create(:appeal))
      end

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)["message"]).to eq "Citation number already exists"
      end
    end

    context "when single BvaDispatchTask exists for user and appeal combination" do
      before { BvaDispatchTask.create_from_root_task(root_task) }

      it "should complete the BvaDispatchTask assigned to the User and the task assigned to the BvaDispatch org" do
        post :outcode, params: params

        expect(response.status).to eq(200)

        tasks = BvaDispatchTask.where(appeal: root_task.appeal, assigned_to: user)

        expect(tasks.length).to eq(1)

        task = tasks[0]

        expect(task.status).to eq("completed")
        expect(task.parent.status).to eq("completed")
        expect(S3Service.files["decisions/" + root_task.appeal.external_id + ".pdf"]).to_not eq nil
        expect(DecisionDocument.find_by(appeal_id: root_task.appeal.id)&.submitted_at).to_not be_nil
      end
    end

    context "when multiple BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 2 }

      before do
        task_count.times do
          org_task = BvaDispatchTask.create_from_root_task(root_task)
          # Set status of org-level task to completed to avoid getting caught by Task.verify_org_task_unique.
          org_task.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        expect(response_detail).to eq("Expected 1 BvaDispatchTask received #{task_count} tasks for appeal "\
                                      "#{root_task.appeal.id}, user #{user.id}")
      end
    end

    context "when no BvaDispatchTasks exists for user and appeal combination" do
      let(:task_count) { 0 }

      it "throws an error" do
        post :outcode, params: params

        expect(response.status).to eq(400)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        expect(response_detail).to eq("Expected 1 BvaDispatchTask received #{task_count} tasks for appeal "\
                                      "#{root_task.appeal.id}, user #{user.id}")
      end
    end

    context "when appeal has already been outcoded" do
      before do
        allow(controller).to receive(:sentry_reporting_is_live?) { true }
        allow(Raven).to receive(:user_context) do |args|
          @raven_user = args
        end
      end

      it "throws an error" do
        BvaDispatchTask.create_from_root_task(root_task)
        post :outcode, params: params
        post :outcode, params: params.merge(citation_number: "A12131989")

        expect(response.status).to eq(400)

        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        task = BvaDispatchTask.find_by(appeal: root_task.appeal, assigned_to: user)
        error_message = "Appeal #{root_task.appeal.id}, task ID #{task.id} has already been outcoded. " \
                        "Cannot outcode the same appeal and task combination more than once"

        expect(response_detail).to eq error_message
        expect(@raven_user[:css_id]).to eq(user.css_id)
      end
    end

    context "when veteran file number doesn't match BGS file number" do
      before do
        allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn) { "123123123" }
      end
      it "throws an error" do
        BvaDispatchTask.create_from_root_task(root_task)
        post :outcode, params: params

        expect(response.status).to eq(500)
        response_detail = JSON.parse(response.body)["errors"][0]["detail"]
        response_title = JSON.parse(response.body)["errors"][0]["title"]

        error_message = "The veteran file number does not match the file number in VBMS"
        error_title = "VBMS::FilenumberDoesNotExist"

        expect(response_detail).to eq error_message
        expect(response_title).to eq error_title
      end
    end
  end
end
