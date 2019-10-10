# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe IntakeStartValidator, :postgres do
  context "#user_may_modify_veteran_file?" do
    let(:veteran) { create(:veteran) }

    let(:intake) do
      ->(user:) do
        create(:intake, veteran_file_number: veteran.file_number, user: user)
      end
    end

    let(:validator) do
      ->(user:) do
        described_class.new(intake: intake[user: user])
      end
    end

    before do
      allow_any_instance_of(BGSService).to receive(:may_modify?) { raise }
    end

    it(
      "throws an exception when user is /not/ api_user" +
      " (because may_modify? is mocked to throw an exception)"
    ) do
      expect { validator[user: nil].send(:user_may_modify_veteran_file?) }.to raise_error
    end

    it "returns true when user /is/ api_user" do
      expect(
        validator[user: User.api_user].send(:user_may_modify_veteran_file?)
      ).to be true
    end
  end
end
