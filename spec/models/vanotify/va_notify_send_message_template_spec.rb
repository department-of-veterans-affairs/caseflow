# frozen_string_literal: true

describe VANotifySendMessageTemplate do
  let(:appeal) { create(:appeal, :active, number_of_claimants: 1) }
  let(:queue_url) { "caseflow_development_send_notifications" }
  let(:info) do
    {
      participant_id: appeal.claimant_participant_id,
      appeal_id: appeal.uuid,
      appeal_type: appeal.class.to_s,
      status: "Test Status"
    }
  end
  let(:template_name) { "Test Template Name" }

  subject do
    VANotifySendMessageTemplate.new(info, template_name)
  end

  describe "instance methods" do
    describe ".participant_id" do
      it "will return the participant_id" do
        expect(subject.participant_id).to eq(info[:participant_id])
      end
    end

    describe ".template_name" do
      it "will return the template_name" do
        expect(subject.template_name).to eq(template_name)
      end
    end

    describe ".appeal_id" do
      it "will return the appeal_id" do
        expect(subject.appeal_id).to eq(info[:appeal_id])
      end
    end

    describe ".appeal_type" do
      it "will return the appeal type" do
        expect(subject.appeal_type).to eq(info[:appeal_type])
      end
    end

    describe ".status" do
      it "will return the status" do
        expect(subject.status).to eq(info[:status])
      end
    end
  end
end
