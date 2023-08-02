# frozen_string_literal: true

describe MembershipRequest do
  before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end
  let(:vha_business_line) { VhaBusinessLine.singleton }

  describe "#save" do
    let(:requestor) { create(:user) }
    let(:decider) { create(:user) }
    let(:organization) { create(:organization) }

    let(:valid_params) do
      {
        organization_id: organization.id,
        requestor: requestor
      }
    end

    context "when decider and decided_at is not present" do
      let(:membership_request) { MembershipRequest.new(valid_params) }
      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.decider).to be_nil
        expect(membership_request.decided_at).to be_nil
      end
    end

    context "when decided_by_id and decided_at is present" do
      let(:decider_params) do
        {
          decider: decider,
          decided_at: 1.minute.ago
        }
      end

      let(:membership_request) { MembershipRequest.new(valid_params.merge(decider_params)) }

      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.decider).to be_present
        expect(membership_request.decided_at).to be_present
      end
    end

    context "when organization id is not present" do
      let(:membership_request) { MembershipRequest.new(requestor: requestor) }

      it "should not save to database" do
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end

    context "when requestor id is not present" do
      let(:membership_request) { MembershipRequest.new(organization_id: organization.id) }

      it "should not save to database" do
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end

    context "when status is not present" do
      let(:membership_request) { MembershipRequest.new(valid_params) }

      it "should not save to database" do
        membership_request.status = nil
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end
  end
  describe "requesting vha predocket access" do
    let(:requestor) { create(:user) }
    let(:organization) { create(:organization) }
    let(:membership_request) { create(:membership_request, requestor: requestor, organization: organization) }

    context "when organization is not predocket" do
      it "should return false when Organization Type is other than VHA" do
        expect(membership_request.requesting_vha_predocket_access?).to be false
      end
    end

    context "When Organization is Predocket - VhaProgramOffice" do
      let(:organization) { VhaProgramOffice.create }

      it "should return true if Organization type is VhaProgramOffice" do
        expect(membership_request.requesting_vha_predocket_access?).to be true
      end
    end

    context "When Organization is Predocket- VhaCaregiverSupport" do
      let(:organization) { VhaCaregiverSupport.create }
      it "should return true if Organization type is VhaCaregiverSupport" do
        expect(membership_request.requesting_vha_predocket_access?).to be true
      end
    end

    context "When Organization type is VhaCamo" do
      let(:organization) { VhaCamo.create }

      it "should return true if Organization type is VhaCamo" do
        expect(membership_request.requesting_vha_predocket_access?).to be true
      end
    end
  end
  describe "#set_decided_at " do
    let(:now) { Time.zone.now }
    let(:requestor) { create(:user) }
    let(:decider) { create(:user) }
    let(:organization) { create(:organization) }
    let(:valid_params) do
      {
        organization_id: organization.id,
        requestor: requestor
      }
    end
    let(:membership_request) { MembershipRequest.create!(valid_params) }

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

    context "Before Hooks - Saving the membership with decidor and changing the status should call before hooks " do
      it "status was assigned" do
        expect(membership_request.decided_at).to be nil
        membership_request.decider = decider
        membership_request.status = "approved"
        membership_request.save
        expect(membership_request.decided_at).to eq now
      end
    end

    context "when status is changed and decidor is provided decided_at should not be nil" do
      it "should return nil if decider is not provided and should return time if both status and decider is present" do
        membership_request.status = "approved"
        expect(membership_request.send(:set_decided_at)).to be nil
        membership_request.decider = decider
        expect(membership_request.send(:set_decided_at)).to eq now
      end
    end
  end

  describe "#create_many_from_orgs" do
    let(:number_of_request) { 3 }
    let(:requestor) { create(:user) }
    let(:organizations) { create_list(:organization, number_of_request) }
    let(:params) do
      {
        requestReason: "notetesting"
      }
    end
    context "when number of organization passed to the method should match the number of request created." do
      it "returns the same number of membership request" do
        membership_request = MembershipRequest.create_many_from_orgs(organizations, params, requestor)
        expect(membership_request.count).to be number_of_request
      end
    end
  end

  describe "#update_status_and_send_email" do
    let(:requestor) { create(:user) }
    let(:decider) { create(:user) }
    let(:organization) { create(:organization) }
    let(:valid_params) do
      {
        organization: organization,
        requestor: requestor
      }
    end
    let(:membership_request) { MembershipRequest.create!(valid_params) }

    context "when status is updated to approved" do
      it "should update the status to approved and send email" do
        expect(membership_request.status).to eq "assigned"
        expect(membership_request.decider).to be nil
        expect(membership_request.decided_at).to be nil
        membership_request.update_status_and_send_email("approved", decider)
        expect(membership_request.status).to eq "approved"
        expect(membership_request.decider).to be decider
        expect(membership_request.decided_at).not_to be nil
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
        expect(jobs[0][:args][0]).to eq "VhaBusinessLineApproved"
        expect(requestor.member_of_organization?(organization)).to be true
        expect(requestor.member_of_organization?(vha_business_line)).to be false
      end
    end

    context "when the user is requesting VHA sub organization access, also add them to the VHA Businessline " do
      let(:organization) { VhaProgramOffice.create!(name: "VhaProgramOffice", url: "pg1") }
      let(:membership_request) { MembershipRequest.create!(organization: organization, requestor: requestor) }
      it "should update the status to approved, send email and also add to VHA BusinessLine" do
        vha_business_line.save
        expect(membership_request.status).to eq "assigned"
        expect(membership_request.decider).to be nil
        expect(membership_request.decided_at).to be nil
        membership_request.update_status_and_send_email("approved", decider)
        expect(membership_request.status).to eq "approved"
        expect(membership_request.decider).to be decider
        expect(membership_request.decided_at).not_to be nil
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
        expect(jobs[0][:args][0]).to eq "VhaPredocketApproved"
        expect(requestor.member_of_organization?(organization)).to be true
        expect(requestor.member_of_organization?(vha_business_line)).to be true
      end
    end
    context "when status is updated to cancelled" do
      it "should update the status to cancelled and send email" do
        expect(membership_request.status).to eq "assigned"
        expect(membership_request.decider).to be nil
        expect(membership_request.decided_at).to be nil
        membership_request.update_status_and_send_email("cancelled", decider)
        expect(membership_request.status).to eq "cancelled"
        expect(membership_request.decider).to be decider
        expect(membership_request.decided_at).not_to be nil
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
        expect(jobs[0][:args][0]).to eq "VhaBusinessLineApproved"
        expect(requestor.member_of_organization?(organization)).to be false
        expect(requestor.member_of_organization?(vha_business_line)).to be false
      end
    end

    context "when status is updated to cancelled and check for user adding to BusinessLine " do
      let(:organization) { VhaProgramOffice.create!(name: "VhaProgramOffice", url: "pg1") }
      let(:membership_request) { MembershipRequest.create!(organization: organization, requestor: requestor) }
      it "should update the status to cancelled, send email and user should be added to businessline" do
        vha_business_line.save
        expect(membership_request.status).to eq "assigned"
        expect(membership_request.decider).to be nil
        expect(membership_request.decided_at).to be nil
        membership_request.update_status_and_send_email("cancelled", decider)
        expect(membership_request.status).to eq "cancelled"
        expect(membership_request.decider).to be decider
        expect(membership_request.decided_at).not_to be nil
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
        expect(jobs[0][:args][0]).to eq "VhaPredocketApproved"
        expect(requestor.member_of_organization?(organization)).to be false
        expect(requestor.member_of_organization?(vha_business_line)).to be true
      end
    end

    context "when status is updated to denied" do
      it "should update the status to denied and send email" do
        expect(membership_request.status).to eq "assigned"
        expect(membership_request.decider).to be nil
        expect(membership_request.decided_at).to be nil
        membership_request.update_status_and_send_email("denied", decider)
        expect(membership_request.status).to eq "denied"
        expect(membership_request.decider).to be decider
        expect(membership_request.decided_at).not_to be nil
        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        expect(jobs.length).to eq(1)
        expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
        expect(jobs[0][:args][0]).to eq "VhaBusinessLineDenied"
      end
    end
  end
end
