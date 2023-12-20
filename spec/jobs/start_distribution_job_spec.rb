# frozen_string_literal: true

describe StartDistributionJob do
  let(:judge) { build_stubbed(:user, css_id: "MYNAMEISJUDGE") }
  let!(:vacols_judge) { build_stubbed(:staff, :judge_role, sdomainid: "MYNAMEISJUDGE") }
  let(:distribution) { Distribution.new(judge: judge) }

  context ".perform" do
    subject { StartDistributionJob.perform_now(distribution) }
    it "calls distribute!" do
      expect(distribution).to receive(:distribute!)
      subject
    end

    context "when distribute! errors" do
      it "logs the error" do
        allow(distribution).to receive(:distribute!).and_raise(StandardError)
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with("StartDistributionJob failed: StandardError")
        subject
      end
    end
  end
end
