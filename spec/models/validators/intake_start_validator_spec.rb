# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe IntakeStartValidator, :postgres do
  context "#user_may_modify_veteran_file?" do
    let(:user) { create(:user) }

    let(:veteran) { create(:veteran) }

    let(:intake) do
      ->(u) do
        create(:intake, veteran_file_number: veteran.file_number, user: u)
      end
    end

    let(:validator) do
      ->(u) do
        described_class.new(intake: intake[user: u])
      end
    end

    # before do
    #   allow_any_instance_of(BGSService).to receive(:may_modify?) { raise }
    # end

    it do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { true }
      expect(validator[user].send(:user_may_modify_veteran_file?)).to be true
    end

    it do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { false }
      expect(validator[user].send(:user_may_modify_veteran_file?)).to be false
    end

    it "returns true when user is api_user" do
      expect(
        validator[User.api_user].send(:user_may_modify_veteran_file?)
      ).to be true
    end
  end
end
