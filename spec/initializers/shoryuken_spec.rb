# frozen_string_literal: true

describe "Shoryuken Initializer" do
  describe "Rails.logger#info" do
    # Ensures that the intialization code in Shoryuken#configure_server doesn't
    # overwrite the Rails logger when running the app server.
    it "does not call Shoryuken.logger#info" do
      expect(Shoryuken.logger).not_to receive(:info)

      Rails.logger.info("Not Shoryuken")
    end
  end
end
