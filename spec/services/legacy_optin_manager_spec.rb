describe LegacyOptinManager do
  before do
    Timecop.freeze(Time.utc(2018, 4, 24, 12, 0, 0))
  end

  let(:user) { Generators::User.build }
  let!(:appeal) { create(:appeal, request_issues: request_issues) }
  let(:request_issues) { [undecided_ri1, undecided_ri2, remand_ri1, remand_ri2, closed_ri1, closed_ri2] }
  let(:legacy_opt_in_manager) { LegacyOptinManager.new(decision_review: appeal) }

  let(:undecided_case) { create(:case, :status_active, bfkey: "undecided", case_issues: [undecided_issue1, undecided_issue2]) }
  let!(:undecided_appeal) { create(:legacy_appeal, vacols_case: undecided_case) }
  let(:undecided_issue1) { create(:case_issue) }
  let(:undecided_issue2) { create(:case_issue) }
  let(:undecided_ri1) { create(:request_issue, vacols_id: undecided_case.bfkey, vacols_sequence_id: undecided_issue1.issseq) }
  let(:undecided_ri2) { create(:request_issue, vacols_id: undecided_case.bfkey, vacols_sequence_id: undecided_issue2.issseq) }

  let(:remand_case) { create(:case, :status_remand, bfkey: "remand", case_issues: [remand_issue1, remand_issue2, hlr_remand_issue]) }
  let(:remand_issue1) { create(:case_issue, :disposition_remanded) }
  let(:remand_issue2) { create(:case_issue, :disposition_remanded) }
  let(:remand_ri1) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue1.issseq) }
  let(:remand_ri2) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue2.issseq) }

  let!(:higher_level_review) { create(:higher_level_review, request_issues: [hlr_remand_ri])}
  let(:hlr_remand_issue) { create(:case_issue, :disposition_remanded) }
  let(:hlr_remand_ri) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: hlr_remand_issue.issseq)}

  let(:already_closed_case) { create(:case, :status_complete,  bfkey: "closed", case_issues: [closed_issue1, closed_issue2], bfdsoc: 1.day.ago, bfddec: 1.year.ago) }
  let(:closed_issue1) { create(:case_issue, :disposition_advance_failure_to_respond, issdcls: 1.year.ago) }
  let(:closed_issue2) { create(:case_issue, :disposition_remand_failure_to_respond, issdcls: 1.year.ago) }
  let(:closed_ri1) { create(:request_issue, vacols_id: already_closed_case.bfkey, vacols_sequence_id: closed_issue1.issseq) }
  let(:closed_ri2) { create(:request_issue, vacols_id: already_closed_case.bfkey, vacols_sequence_id: closed_issue2.issseq) }

  context "#process!" do
    before do
      RequestStore[:current_user] = user
    end

    subject { legacy_opt_in_manager.process! }

    context "When issues are opted in" do
      let!(:undecided_optin1) { create(:legacy_issue_optin, request_issue: undecided_ri1, vacols_id: undecided_ri1.vacols_id, vacols_sequence_id: undecided_ri1.vacols_sequence_id) }
      let!(:remand_optin1) { create(:legacy_issue_optin, request_issue: remand_ri1, vacols_id: remand_ri1.vacols_id, vacols_sequence_id: remand_ri1.vacols_sequence_id) }
      let!(:closed_optin1) { create(:legacy_issue_optin, request_issue: closed_ri1,  vacols_id: closed_ri1.vacols_id, vacols_sequence_id: closed_ri1.vacols_sequence_id) }

      let(:issue) { Issue.load_from_vacols(undecided_issue1.reload.attributes) }

      context "when there are still open issues on the appeal" do
        it "updates the disposition and disposition date" do
          subject

          undecided_case.reload
          remand_case.reload
          already_closed_case.reload

          undecided_issue1.reload
          remand_issue1.reload
          closed_issue1.reload

          expect(undecided_optin1.optin_processed_at).to eq(Time.zone.now)
          expect(undecided_issue1.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(undecided_issue1.issdcls).to eq(Time.zone.today)
          expect(remand_issue1.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(remand_issue1.issdcls).to eq(Time.zone.today)
          expect(closed_issue1.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(closed_issue1.issdcls).to eq(Time.zone.today)
          expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
          expect(issue).to be_closed
        end

        it "does not close the appeal (or change already closed appeal)" do
          expect(undecided_case).to_not be_closed
          expect(remand_case).to_not be_closed
          expect(already_closed_case).to be_closed
          expect(already_closed_case.bfddec).to eq(1.year.ago.to_date)
        end

        context "when the issues are rolled back on an open appeal" do
          before do
            subject # process opt_ins first
            undecided_optin1.create_rollback!
            remand_optin1.create_rollback!
            closed_optin1.create_rollback!
          end

          it "rollsback the disposition and date" do
            # subject # process opt_ins first
            # undecided_optin1.create_rollback!
            # remand_optin1.create_rollback!
            # closed_optin1.create_rollback!
# binding.pry
            subject

            undecided_issue1.reload
            remand_issue1.reload
            closed_issue1.reload
binding.pry
            expect(undecided_issue1.issdc).to be_nil
            expect(undecided_issue1.issdcls).to be_nil
            expect(remand_issue1.issdc).to eq('3')
            expect(remand_issue1.issdcls).to eq(remand_optin1.original_disposition_date)
            expect(closed_issue1.issdc).to eq('G')
            expect(closed_issue1.issdcls).to eq(1.year.ago.to_date)
          end

          it "does not change the appeals" do

          end
        end
      end

      context "when the last issue on the appeal is closed" do
        let!(:undecided_optin2) { create(:legacy_issue_optin, request_issue: undecided_ri2) }
        let!(:remand_optin2) { create(:legacy_issue_optin, request_issue: remand_ri2) }
        let!(:closed_optin2) { create(:legacy_issue_optin, request_issue: closed_ri2) }
        let!(:hlr_remand_optin) { create(:legacy_issue_optin, request_issue: hlr_remand_ri) }

        before do
          LegacyOptinManager.new(decision_review: higher_level_review).process!
          subject
        end

        it "closes the undecided issues and closes the undecided appeal" do
          expect(undecided_optin1.reload.optin_processed_at).to eq(Time.zone.now)
          expect(undecided_issue1.reload.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(undecided_issue1.issdcls).to eq(Time.zone.today)
          expect(undecided_optin2.reload.optin_processed_at).to eq(Time.zone.now)
          expect(undecided_issue2.reload.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(undecided_issue2.issdcls).to eq(Time.zone.today)

          expect(undecided_case.reload).to be_closed
        end

        it "rolls back remand issues, closes the remand, and creates a follow up appeal" do
          expect(remand_issue1.reload.issdc).to eq('3')
          expect(remand_issue1.issdcls).to eq(remand_optin1.original_disposition_date)
          expect(remand_issue2.reload.issdc).to eq('3')
          expect(remand_issue2.issdcls).to eq(remand_optin2.original_disposition_date)

          # check that remand opted in from another decision review is also rolled back
          expect(hlr_remand_issue.reload.issdc).to eq('3')

          expect(remand_case.reload.bfmpro).to eq("HIS")
          follow_up_appeal = VACOLS::Case.find_by(bfkey: "remandP")
          expect(follow_up_appeal.bfdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          follow_up_appeal_issues = VACOLS::CaseIssue.where(isskey: "remandP")
          expect(follow_up_appeal_issues.count).to eq(3)
        end

        it "closes the closed issues and does not re-close the already closed appeal" do
          expect(closed_issue1.reload.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(closed_issue1.issdcls).to eq(Time.zone.today)
          expect(closed_issue2.reload.issdc).to eq(LegacyOptinManager::VACOLS_DISPOSITION_CODE)
          expect(closed_issue2.issdcls).to eq(Time.zone.today)

          expect(already_closed_case.reload).to be_closed
          expect(already_closed_case.bfddec).to eq(1.year.ago.to_date)
        end

        # context "when issues are rolled back on a closed appeal" do
        #   undecided_optin2.create_rollback!
        #   remand_optin2.create_rollback!
        #   closed_optin2.create_rollback!
        #
        #   subject
        #
        #   it "rollsback the dispositions and date" do
        #
        #   end
        #
        #   it "reopens an undecided appeal" do
        #
        #   end
        #
        #   it "does not reopen the previously closed appeal" do
        #
        #   end
        #
        #   it "reverts a remanded appeal, deletes the post remand appeal" do
        #
        #   end
        #
        #   it "re-opts in the remanded issues that were not rolled back" do
        #
        #   end
        # end
      end
    end
  end
end
