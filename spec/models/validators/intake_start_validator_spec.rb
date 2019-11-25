# frozen_string_literal: true

describe IntakeStartValidator, :postgres do
  context "#validate" do
    let(:user) { create(:user) }

    let(:veteran) { create(:veteran) }

    let(:intake) do
      # IntakeStartValidator expects an uncommitted intake (hence new)
      Intake.new(veteran_file_number: veteran.file_number, user: user)
    end

    let(:validator) do
      described_class.new(intake: intake)
    end

    let(:validate_error_code) do
      validator.validate
      intake.error_code
    end

    it "sets no error_code when BGS allows modification" do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { true }
      expect(validate_error_code).to be nil
    end

    it "sets error_code \"veteran_not_modifiable\" when BGS does not allow modification" do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { false }
      expect(validate_error_code).to eq "veteran_not_modifiable"
    end

    context "user is api_user" do
      let(:user) { User.api_user }

      it "sets no error_code when user is User.api_user" do
        expect(validate_error_code).to be nil
      end
    end
  end
end
