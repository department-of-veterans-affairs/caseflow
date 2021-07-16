# frozen_string_literal: true

describe "Caseflow::Error" do
  describe "ActionForbiddenError" do
    let(:error_type) { Caseflow::Error::ActionForbiddenError }

    context "when there are no input arguments" do
      subject { fail(Caseflow::Error::ActionForbiddenError) }

      it "raises the correct type of error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(error_type)
        end
      end
    end

    context "when the input hash contains a single element" do
      let(:message_text) { "This action is not allowed" }
      let(:args) { { message: message_text } }

      subject { fail(Caseflow::Error::ActionForbiddenError, args) }

      it "raises the correct type of error with the correct parameter" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(error_type)
          expect(error.message).to eq(message_text)
        end
      end
    end
  end

  describe "TransientError" do
    let(:error_type) { Caseflow::Error::TransientError }

    subject { fail error_type, message: "oops!" }

    context ".ignorable?" do
      it "acts like ignorable BGS or VBMS error" do
        expect { subject }.to raise_error(error_type) do |error|
          expect(error).to be_ignorable
        end
      end
    end
  end

  describe "MissingDecisionDate" do
    let(:error_type) { Caseflow::Error::MissingDecisionDate }

    subject { fail error_type, request_issue_id: 42 }

    it "displays the correct title and message" do
      expect { subject }.to raise_error do |error|
        expect(error.title).to eq("Missing Decision Date")
        expect(error.message).to eq("Request issue 42 does not have a decision date")
      end
    end
  end
end
