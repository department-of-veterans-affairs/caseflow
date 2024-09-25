# frozen_string_literal: true

describe ExternalApi::VbmsDocumentSeriesForAppeal do
  let(:appeal) { create(:appeal) }
  let(:mock_sensitivity_checker) { instance_double(SensitivityChecker, sensitivity_levels_compatible?: true) }

  before do
    allow(SensitivityChecker).to receive(:new).and_return(mock_sensitivity_checker)
  end

  describe "#fetch" do
    context "with send_current_user_cred feature toggle enabled" do
      let!(:user) do
        user = create(:user)
        RequestStore.store[:current_user] = user
      end

      before do
        expect(VBMS::Client).to receive(:from_env_vars).and_return(true)
        expect(ExternalApi::VBMSService).to receive(:send_and_log_request).and_return(true)
        FeatureToggle.enable!(:send_current_user_cred)
      end

      after { FeatureToggle.disable!(:send_current_user_cred) }

      it "check user sensitivity compatibility before calling any APIs" do
        expect(mock_sensitivity_checker).to receive(:sensitivity_levels_compatible?)
          .with(user: user, veteran: appeal.veteran).and_return(true)

        described_class.new(file_number: appeal.veteran_file_number).fetch
      end
    end
  end
end
