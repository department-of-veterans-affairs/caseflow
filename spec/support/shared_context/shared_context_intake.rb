# frozen_string_literal: true

require "./spec/support/shared_context/shared_context_legacy_appeal.rb"

RSpec.configure { |rspec| rspec.shared_context_metadata_behavior = :apply_to_host_groups }

RSpec.shared_context "intake", shared_context: :appealrepo do
  context "when benefit type is non comp" do
    before { RequestStore[:current_user] = user }
    let(:benefit_type) { "voc_rehab" }

    it "creates DecisionReviewTask" do
      subject
      intake.detail.reload
      expect(intake.detail.tasks.count).to eq(1)
      expect(intake.detail.tasks.first).to be_a(DecisionReviewTask)
    end

    it "adds user to organization" do
      subject
      expect(OrganizationsUser.find_by(user: user, organization: intake.detail.business_line)).to_not be_nil
    end

    context "when a legacy VACOLS opt-in occurs" do
      include_context "legacy appeal", include_shared: true

      let(:issue_data) do
        {
          profile_date: "2018-04-30T11:11:00.000-04:00",
          reference_id: "reference-id",
          decision_text: "decision text",
          vacols_id: legacy_appeal.vacols_id,
          vacols_sequence_id: vacols_issue.issseq
        }
      end

      context "legacy_opt_in_approved is false" do
        it "does not submit a LegacyIssueOptin" do
          expect(LegacyIssueOptin.count).to eq 0

          subject
          expect(LegacyIssueOptin.count).to eq 0
        end
      end

      context "legacy_opt_approved is true" do
        let(:legacy_opt_in_approved) { true }

        it "submits a LegacyIssueOptin" do
          expect(LegacyIssueOptin.count).to eq 0
          expect_any_instance_of(LegacyOptinManager).to receive(:process!).once

          subject

          expect(LegacyIssueOptin.count).to eq 1
        end
      end
    end

    context "when the intake was already complete" do
      let(:completed_at) { Time.zone.now }

      it "does nothing" do
        subject

        expect(Fakes::VBMSService).to_not have_received(:establish_claim!)
        expect(Fakes::VBMSService).to_not have_received(:create_contentions!)
        expect(Fakes::VBMSService).to_not have_received(:associate_rating_request_issues!)
      end
    end
  end
end

RSpec.shared_context "completed intake", shared_context: :appealrepotoo do
  context "when end product creation fails" do
    let(:unknown_error) do
      Caseflow::Error::EstablishClaimFailedInVBMS.new("error")
    end

    it "clears pending status" do
      allow(detail).to receive(:establish!).and_raise(unknown_error)

      subject

      expect(intake.completion_status).to eq("success")
      expect(intake.detail.establishment_error).to eq(unknown_error.inspect)
    end
  end
end
