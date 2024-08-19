# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalApi::VaBoxService, type: :service do
  let(:client_secret) { "fake_client_secret" }
  let(:client_id) { "fake_client_id" }
  let(:enterprise_id) { "fake_enterprise_id" }
  let(:private_key) { "-----BEGIN ENED PRIVATE KEY-----\nFAKE_PRIVATE_KEY\n-----END ENCRYPTED PRIVATE KEY-----\n" }
  let(:passphrase) { "fake_passphrase" }

  subject do
    described_class.new(
      client_secret: client_secret,
      client_id: client_id,
      enterprise_id: enterprise_id,
      private_key: private_key,
      passphrase: passphrase
    )
  end

  describe "#initialize" do
    it "initializes with the correct client_secret" do
      expect(subject.client_secret).to eq(client_secret)
    end

    it "initializes with the correct client_id" do
      expect(subject.client_id).to eq(client_id)
    end

    it "initializes with the correct enterprise_id" do
      expect(subject.enterprise_id).to eq(enterprise_id)
    end

    it "initializes with the correct private_key" do
      expect(subject.private_key).to eq(private_key)
    end

    it "initializes with the correct passphrase" do
      expect(subject.passphrase).to eq(passphrase)
    end
  end

  describe "#initialized?" do
    it "returns the initialized state" do
      expect(subject.initialized?).to be_nil
    end
  end

  describe "#fetch_access_token" do
    let(:access_token) { "fake_access_token" }

    before do
      allow(subject).to receive(:fetch_jwt_access_token)
        .and_return({ "access_token" => access_token, "expires_in" => Time.now.to_i + 3600 })
    end

    it "fetches and sets the access token" do
      subject.fetch_access_token
      expect(subject.instance_variable_get(:@access_token)).to eq(access_token)
    end
  end

  describe "#public_upload_file" do
    let(:file_path) { "path/to/file" }
    let(:folder_id) { "12345" }

    it "calls upload_file with correct parameters" do
      expect(subject).to receive(:upload_file).with(file_path, folder_id)
      subject.public_upload_file(file_path, folder_id)
    end
  end
end
