# frozen_string_literal: true

describe VhaMembershipRequestMailBuilder, :postgres do
  include ActiveJob::TestHelper

  before do
    create_vha_orgs
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  let(:camo_org) { VhaCamo.singleton }
  let(:vha_business_line) { VhaBusinessLine.singleton }
  let(:requestor) { create(:user, full_name: "Alice", email: "alice@test.com", css_id: "ALICEREQUEST") }
  let(:membership_requests) do
    [
      create(:membership_request, requestor: requestor, organization: vha_business_line),
      create(:membership_request, requestor: requestor, organization: camo_org)
    ]
  end

  describe "#initialize" do
    subject { described_class.new(membership_requests) }

    it "sets the requests instance variable" do
      expect(subject.instance_variable_get(:@membership_requests)).to eq(membership_requests)
    end

    it "sets the requestor instance variable based on the .requestor attribute of any of the requests" do
      expect(subject.instance_variable_get(:@requestor)).to eq(requestor)
    end
  end

  describe "send email after creation" do
    subject { described_class.new(membership_requests).send_email_after_creation }

    it "should enqueue a job to send a requestor email and emails to each requested organization" do
      subject

      jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

      user_email_count = jobs.count { |h| h[:args][0] == "UserRequestCreated" }
      admin_email_count = jobs.count { |h| h[:args][0] == "AdminRequestMade" }
      expect(admin_email_count).to eq(2)
      expect(user_email_count).to eq(1)
      expect(jobs.length).to eq(user_email_count + admin_email_count)

      camo_email_job = jobs.find do |job|
        args = job[:args][1]
        args["to"] == COPY::VHA_BENEFIT_EMAIL_ADDRESS &&
          args["organization_name"] == camo_org.name &&
          args["subject"] == COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED
      end

      vha_business_line_email_job = jobs.find do |job|
        args = job[:args][1]
        args["to"] == COPY::VHA_BENEFIT_EMAIL_ADDRESS &&
          args["organization_name"] == vha_business_line.name &&
          args["subject"] == COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED
      end

      requestor_email_job = jobs.find do |job|
        args = job[:args][1]
        args["subject"] == COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED
      end

      expect(camo_email_job).to_not eq(nil)
      expect(vha_business_line_email_job).to_not eq(nil)
      expect(requestor_email_job).to_not eq(nil)
      expect(jobs.map { |job| job[:queue] }).to all(eq "caseflow_test_low_priority")
    end
  end

  describe "send email request approved" do
    subject { described_class.new(request).send_email_request_approved }

    context "approving a request to the vha business line" do
      let(:request) { membership_requests[0] }

      it "should enqueue a job to send a requestor email for the business line approved" do
        subject

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        requestor_email_job = jobs.find do |job|
          type = job[:args][0]
          args = job[:args][1]
          type == "VhaBusinessLineApproved" &&
            args["organization_name"] == vha_business_line.name &&
            args["accessible_groups"] == requestor.organizations.map(&:name) &&
            args["pending_organization_request_names"] == ["Veterans Health Administration", "VHA CAMO"]
        end

        expect(requestor_email_job).to_not eq(nil)
      end
    end

    context "approving a request to a vha predocket organization other than the business line" do
      let(:request) { membership_requests[1] }

      it "should enqueue a job to send a requestor email for the predocket approved" do
        subject

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        requestor_email_job = jobs.find do |job|
          type = job[:args][0]
          args = job[:args][1]
          type == "VhaPredocketApproved" &&
            args["organization_name"] == camo_org.name &&
            args["accessible_groups"] == requestor.organizations.map(&:name) &&
            args["pending_organization_request_names"] == ["Veterans Health Administration", "VHA CAMO"]
        end

        expect(requestor_email_job).to_not eq(nil)
      end
    end
  end

  describe "send email request denied" do
    subject { described_class.new(request).send_email_request_denied }

    context "denying a request to the vha business line" do
      let(:request) { membership_requests[0] }

      it "should enqueue a job to send a requestor email for the business line denied" do
        subject

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        requestor_email_job = jobs.find do |job|
          type = job[:args][0]
          args = job[:args][1]
          type == "VhaBusinessLineDenied" &&
            args["organization_name"] == vha_business_line.name &&
            args["accessible_groups"] == requestor.organizations.map(&:name) &&
            args["pending_organization_request_names"] == ["Veterans Health Administration", "VHA CAMO"]
        end

        expect(requestor_email_job).to_not eq(nil)
      end
    end

    context "denying a request to a vha predocket organization other than the business line" do
      let(:request) { membership_requests[1] }

      it "should enqueue a job to send a requestor email for the predocket denied" do
        subject

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

        requestor_email_job = jobs.find do |job|
          type = job[:args][0]
          args = job[:args][1]
          type == "VhaPredocketDenied" &&
            args["organization_name"] == camo_org.name &&
            args["accessible_groups"] == requestor.organizations.map(&:name) &&
            args["pending_organization_request_names"] == ["Veterans Health Administration", "VHA CAMO"] &&
            args["has_vha_access"] == false
        end

        expect(requestor_email_job).to_not eq(nil)
      end

      context "user is already a member of the vha business line" do
        let(:new_user) { create(:user, full_name: "Donna Tello", email: "donna@test.com", css_id: "TELLOVHA") }
        let(:request) { create(:membership_request, requestor: new_user, organization: camo_org) }

        before do
          vha_business_line.add_user(new_user)
        end

        it "should enqueue a job to send a requestor email for the predocket denied" do
          subject

          jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
            .select { |job| job[:job] == Memberships::SendMembershipRequestMailerJob }

          requestor_email_job = jobs.find do |job|
            type = job[:args][0]
            args = job[:args][1]
            type == "VhaPredocketDenied" &&
              args["organization_name"] == camo_org.name &&
              args["accessible_groups"] == new_user.organizations.map(&:name) &&
              args["pending_organization_request_names"] == ["VHA CAMO"] &&
              args["has_vha_access"] == true
          end

          expect(requestor_email_job).to_not eq(nil)
        end
      end
    end
  end

  private

  def create_vha_orgs
    create(:business_line, name: "Veterans Health Administration", url: "vha")
    VhaCamo.singleton
    VhaCaregiverSupport.singleton
    create(:vha_program_office,
           name: "Community Care - Veteran and Family Members Program",
           url: "community-care-veteran-and-family-members-program")
    create(:vha_program_office,
           name: "Community Care - Payment Operations Management",
           url: "community-care-payment-operations-management")
    create(:vha_program_office,
           name: "Member Services - Health Eligibility Center",
           url: "member-services-health-eligibility-center")
    create(:vha_program_office, name: "Member Services - Beneficiary Travel", url: "member-services-beneficiary-travel")
    create(:vha_program_office, name: "Prosthetics", url: "prosthetics")
  end
end
