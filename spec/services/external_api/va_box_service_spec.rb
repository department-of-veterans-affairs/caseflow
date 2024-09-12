# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExternalApi::VaBoxService, type: :service do
  def set_env_vars
    ENV["BOX_CLIENT_SECRET"] = "fake_client_secret"
    ENV["BOX_CLIENT_ID"] = "fake_client_id"
    ENV["BOX_ENTERPRISE_ID"] = "fake_enterprise_id"
    ENV["BOX_PRIVATE_KEY"] = "-----BEGIN ENED PRIVATE KEY-----\nFAKE_PRIVATE_KEY\n-----END ENCRYPTED PRIVATE KEY-----\n"
    ENV["BOX_PASSPHRASE"] = "fake_passphrase"
  end

  before { set_env_vars }

  subject do
    described_class.new
  end

  describe "#initialize" do
    it "initializes with the correct client_secret" do
      expect(subject.client_secret).to eq(ENV["BOX_CLIENT_SECRET"])
    end

    it "initializes with the correct client_id" do
      expect(subject.client_id).to eq(ENV["BOX_CLIENT_ID"])
    end

    it "initializes with the correct enterprise_id" do
      expect(subject.enterprise_id).to eq(ENV["BOX_ENTERPRISE_ID"])
    end

    it "initializes with the correct private_key" do
      expect(subject.private_key).to eq(ENV["BOX_PRIVATE_KEY"])
    end

    it "initializes with the correct passphrase" do
      expect(subject.passphrase).to eq(ENV["BOX_PASSPHRASE"])
    end
  end

  describe "#ensure_access_token" do
    let(:access_token) { "fake_access_token" }

    before do
      allow(subject).to receive(:fetch_jwt_access_token)
        .and_return({ access_token: access_token, expires_in: 3600 })
    end

    it "fetches and sets the access token" do
      subject.ensure_access_token
      expect(subject.instance_variable_get(:@access_token)).to eq(access_token)
    end
  end

  describe "#upload_file" do
    let(:file_path) { "path/to/file" }
    let(:folder_id) { "12345" }

    it "calls upload_file with correct parameters" do
      expect(subject).to receive(:upload_file).with(file_path, folder_id)
      subject.upload_file(file_path, folder_id)
    end
  end
end
