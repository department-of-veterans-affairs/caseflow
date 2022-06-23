# frozen_string_literal: true

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
    end
end