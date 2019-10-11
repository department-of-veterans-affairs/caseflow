# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe IntakeStartValidator, :postgres do
  context "#user_may_modify_veteran_file?" do
    let(:user) { create(:user) }

    let(:veteran) { create(:veteran) }

    let(:intake) do
      create(:intake, veteran_file_number: veteran.file_number, user: user)
    end

    let(:validator) do
      described_class.new(intake: intake)
    end

    it "returns true when BGS allows modification" do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { true }
      expect(validator.send(:user_may_modify_veteran_file?)).to be true
    end

    it "returns false when BGS does not allow modification" do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { false }
      expect(validator.send(:user_may_modify_veteran_file?)).to be false
    end

    it "returns true when user is User.api_user" do
      user = User.api_user
      expect(validator.send(:user_may_modify_veteran_file?)).to be true
    end
  end
end
