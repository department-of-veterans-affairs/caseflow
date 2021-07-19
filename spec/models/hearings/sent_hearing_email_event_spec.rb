# frozen_string_literal: true

describe SentHearingEmailEvent do
  context "#create" do
    let(:user) { create(:user) }
    let(:hearing) { create(:hearing) }
    let(:email_type) { "confirmation" }
    let(:recipient_role) { "appellant" }

    subject do
      SentHearingEmailEvent.create(
        hearing: hearing,
        email_type: email_type,
        recipient_role: recipient_role,
        sent_by: user
      )
    end

    it "automatically sets the sent_at date" do
      expect(subject.sent_at).not_to be(nil)
    end

    context "invalid email type field" do
      let(:email_type) { "INVALID" }

      it "fails validation" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "invalid recipient role" do
      let(:recipient_role) { "INVALID" }

      it "fails validation" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  context "#update" do
    let(:event) { create(:sent_hearing_email_event) }

    it "fails with readonly error" do
      expect { event.update!(email_address: "new@caseflow.va.gov") }.to(
        raise_error(ActiveRecord::ReadOnlyRecord)
      )
    end
  end
end
