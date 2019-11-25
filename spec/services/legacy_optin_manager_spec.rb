# frozen_string_literal: true

describe LegacyOptinManager, :all_dbs do
  before do
    Timecop.freeze(Time.zone.now)
  end

  let(:user) { Generators::User.build }
  let(:closed_disposition_date) { 1.year.ago }
  let!(:appeal) { create(:appeal, request_issues: request_issues) }
  let(:request_issues) { [undecided_ri1, undecided_ri2, remand_ri1, remand_ri2, closed_ri1, closed_ri2] }
  let(:legacy_opt_in_manager) { LegacyOptinManager.new(decision_review: appeal) }

  let!(:undecided_issue1) { create(:case_issue, issseq: 1) }
  let!(:undecided_issue2) { create(:case_issue, issseq: 2) }
  let!(:undecided_case) do
    create(:case, :status_active, bfcurloc: "77", bfkey: "undecided", case_issues: [undecided_issue1, undecided_issue2])
  end
  let!(:undecided_location) { create(:priorloc, lockey: undecided_case.bfkey, locstto: "77") }
  let!(:undecided_appeal) { create(:legacy_appeal, vacols_case: undecided_case) }
  let(:undecided_ri1) do
    create(:request_issue, vacols_id: undecided_case.bfkey, vacols_sequence_id: undecided_issue1.issseq)
  end
  let(:undecided_ri2) do
    create(:request_issue, vacols_id: undecided_case.bfkey, vacols_sequence_id: undecided_issue2.issseq)
  end

  let(:remand_case) do
    create(:case, :status_remand, bfkey: "remand", case_issues: [remand_issue1, remand_issue2, hlr_remand_issue])
  end
  let!(:remand_location) { create(:priorloc, lockey: remand_case.bfkey, locstto: "97") }
  let(:remand_issue1) { create(:case_issue, :disposition_remanded, issseq: 1) }
  let(:remand_issue2) { create(:case_issue, :disposition_manlincon_remand, issseq: 2) }
  let(:remand_ri1) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue1.issseq) }
  let(:remand_ri2) { create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: remand_issue2.issseq) }

  let!(:higher_level_review) { create(:higher_level_review, request_issues: [hlr_remand_ri]) }
  let(:hlr_remand_issue) { create(:case_issue, :disposition_remanded, issseq: 3) }
  let(:hlr_remand_ri) do
    create(:request_issue, vacols_id: remand_case.bfkey, vacols_sequence_id: hlr_remand_issue.issseq)
  end

  let(:already_closed_case) do
    create(:case,
           :status_complete,
           bfkey: "closed",
           case_issues: [closed_issue1, closed_issue2],
           bfdsoc: 1.day.ago,
           bfddec: closed_disposition_date)
  end
  let(:closed_issue1) do
    create(:case_issue, :disposition_advance_failure_to_respond, issseq: 1, issdcls: closed_disposition_date)
  end
  let(:closed_issue2) do
    create(:case_issue, :disposition_remand_failure_to_respond, issseq: 2, issdcls: closed_disposition_date)
  end
  let(:closed_ri1) do
    create(:request_issue, vacols_id: already_closed_case.bfkey, vacols_sequence_id: closed_issue1.issseq)
  end
  let(:closed_ri2) do
    create(:request_issue, vacols_id: already_closed_case.bfkey, vacols_sequence_id: closed_issue2.issseq)
  end

  def vacols_issue(vacols_id, vacols_sequence_id)
    # Use this instead of reload for VACOLS issues, because reload mutates the issseq
    VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)
  end

  context "#process!" do
    before do
      RequestStore[:current_user] = user
    end

    subject { legacy_opt_in_manager.process! }

    context "When issues are opted in" do
      let!(:undecided_optin1) do
        create(:legacy_issue_optin,
               request_issue: undecided_ri1,
               vacols_id: undecided_ri1.vacols_id,
               vacols_sequence_id: undecided_ri1.vacols_sequence_id)
      end
      let!(:remand_optin1) do
        create(:legacy_issue_optin,
               request_issue: remand_ri1,
               vacols_id: remand_ri1.vacols_id,
               vacols_sequence_id: remand_ri1.vacols_sequence_id)
      end
      let!(:closed_optin1) do
        create(:legacy_issue_optin,
               request_issue: closed_ri1,
               vacols_id: closed_ri1.vacols_id,
               vacols_sequence_id: closed_ri1.vacols_sequence_id)
      end

      let(:issue) { Issue.load_from_vacols(vacols_issue("undecided", 1).attributes) }

      context "when there are still open issues on the appeal" do
        it "updates the disposition and disposition date, does not change appeals" do
          subject

          expect(undecided_optin1.optin_processed_at).to be_within(1.second).of Time.zone.now
          expect(vacols_issue("undecided", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("undecided", 1).issdcls).to eq(Time.zone.today)
          expect(vacols_issue("remand", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("remand", 1).issdcls).to eq(Time.zone.today)
          expect(vacols_issue("closed", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("closed", 1).issdcls).to eq(Time.zone.today)
          expect(issue.disposition).to eq(:ama_soc_ssoc_opt_in)
          expect(issue).to be_closed

          expect(undecided_case.reload).to_not be_closed
          expect(remand_case.reload).to_not be_closed
          expect(already_closed_case.reload).to be_closed
          expect(already_closed_case.bfddec).to eq(closed_disposition_date.to_date)
        end

        context "when the issues are rolled back on an open appeal" do
          before do
            LegacyOptinManager.new(decision_review: appeal).process!
          end

          it "rollsback the disposition and date and does not change appeals" do
            undecided_optin1.flag_for_rollback!
            remand_optin1.flag_for_rollback!
            closed_optin1.flag_for_rollback!

            subject

            expect(vacols_issue("undecided", 1).issdc).to be_nil
            expect(vacols_issue("undecided", 1).issdcls).to be_nil
            expect(vacols_issue("remand", 1).issdc).to eq(remand_optin1.original_disposition_code)
            expect(vacols_issue("remand", 1).issdcls).to eq(remand_optin1.original_disposition_date)
            expect(vacols_issue("closed", 1).issdc).to eq(closed_optin1.original_disposition_code)
            expect(vacols_issue("closed", 1).issdcls).to eq(closed_disposition_date.to_date)

            expect(undecided_case.reload).to_not be_closed
            expect(remand_case.reload).to_not be_closed
            expect(already_closed_case.reload).to be_closed
            expect(already_closed_case.bfddec).to eq(closed_disposition_date.to_date)
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
        end

        it "closes the undecided issues and closes the undecided appeal" do
          subject
          expect(undecided_optin1.reload.optin_processed_at).to be_within(1.second).of Time.zone.now
          expect(vacols_issue("undecided", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("undecided", 1).issdcls).to eq(Time.zone.today)
          expect(undecided_optin2.reload.optin_processed_at).to be_within(1.second).of Time.zone.now
          expect(vacols_issue("undecided", 2).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("undecided", 2).issdcls).to eq(Time.zone.today)

          expect(undecided_case.reload).to be_closed
        end

        it "rolls back remand issues, closes the remand, and creates a follow up appeal" do
          subject
          expect(vacols_issue("remand", 1).issdc).to eq(remand_optin1.original_disposition_code)
          expect(vacols_issue("remand", 1).issdcls).to eq(remand_optin1.original_disposition_date)
          expect(vacols_issue("remand", 2).issdc).to eq(remand_optin2.original_disposition_code)
          expect(vacols_issue("remand", 2).issdcls).to eq(remand_optin2.original_disposition_date)

          # check that remand opted in from another decision review is also rolled back
          expect(vacols_issue("remand", 3).issdc).to eq(hlr_remand_optin.original_disposition_code)

          expect(remand_case.reload.bfmpro).to eq("HIS")
          follow_up_appeal = VACOLS::Case.find_by(bfkey: "remandP")
          expect(follow_up_appeal.bfdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          follow_up_appeal_issues = VACOLS::CaseIssue.where(isskey: "remandP")
          expect(follow_up_appeal_issues.count).to eq(3)
        end

        it "closes the closed issues and does not re-close the already closed appeal" do
          subject
          expect(vacols_issue("closed", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("closed", 1).issdcls).to eq(Time.zone.today)
          expect(vacols_issue("closed", 2).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
          expect(vacols_issue("closed", 2).issdcls).to eq(Time.zone.today)

          expect(already_closed_case.reload).to be_closed
          expect(already_closed_case.bfddec).to eq(closed_disposition_date.to_date)
        end

        context "when issues are rolled back on a closed appeal" do
          before do
            LegacyOptinManager.new(decision_review: appeal).process!
          end

          it "reopens an undecided appeal and rollsback the dispositions" do
            expect(vacols_issue("undecided", 2).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
            expect(undecided_case.reload).to be_closed
            undecided_optin2.flag_for_rollback!

            subject

            expect(vacols_issue("undecided", 2).issdc).to be_nil
            expect(vacols_issue("undecided", 2).issdcls).to be_nil
            expect(undecided_case.reload).to_not be_closed
          end

          it "does not reopen the previously closed appeal but rollsback dispositions" do
            expect(vacols_issue("closed", 2).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
            expect(already_closed_case.reload).to be_closed
            closed_optin2.flag_for_rollback!

            subject

            expect(vacols_issue("closed", 2).issdc).to eq("X")
            expect(vacols_issue("closed", 2).issdcls).to eq(closed_disposition_date.to_date)

            expect(already_closed_case.reload).to be_closed
            expect(already_closed_case.bfddec).to eq(closed_disposition_date.to_date)
          end

          it "reopens the remand, deletes the post remand, re-opts in remanded issues and rollsback the disposition" do
            follow_up_appeal = VACOLS::Case.find_by(bfkey: "remandP")
            follow_up_appeal_issues = VACOLS::CaseIssue.where(isskey: "remandP")

            expect(vacols_issue("remand", 2).issdc).to eq(remand_optin2.original_disposition_code)
            expect(remand_case.reload.bfmpro).to eq("HIS")
            expect(follow_up_appeal.bfdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
            expect(follow_up_appeal_issues.count).to eq(3)
            remand_optin2.flag_for_rollback!

            subject

            # issue being rolled back is set to original state
            expect(vacols_issue("remand", 2).issdc).to eq(remand_optin2.original_disposition_code)
            expect(vacols_issue("remand", 2).issdcls).to eq(remand_optin2.original_disposition_date)

            # other remand issue is re-opted in
            expect(vacols_issue("remand", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
            expect(vacols_issue("remand", 1).issdcls).to eq(Time.zone.today)

            # remand issue opted in on another decision review is also re-opted in
            expect(vacols_issue("remand", 3).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
            expect(vacols_issue("remand", 3).issdcls).to eq(Time.zone.today)

            expect(remand_case.reload.bfmpro).to eq("REM")
            expect { follow_up_appeal.reload }.to raise_error do |error|
              expect(error).to be_a(ActiveRecord::RecordNotFound)
            end
            expect(follow_up_appeal_issues.reload.count).to eq(0)
          end
        end
      end
    end
  end
end
