# frozen_string_literal: true

describe DependenciesCheckJob do
  context "when Monitor env is set" do
    it "writes report in cache" do
      monitor_url = "http://www.example.com"
      stub_const("ENV", "MONITOR_URL" => monitor_url)
      http_library = FakeHttpLibrary.new
      allow(http_library).to receive(:get).with(monitor_url, any_args)
        .and_return(FakeResponse.new)

      DependenciesCheckJob.perform_now(http_library)

      expect(Rails.cache.read(:dependencies_report)).to eq "fake raw body"
    end

    it "uses HTTPI by default" do
      monitor_url = "http://www.example.com"
      stub_const("ENV", "MONITOR_URL" => monitor_url)

      expect(HTTPI).to receive(:get).and_return(FakeResponse.new)

      DependenciesCheckJob.perform_now
    end

    context "when monitor URL is invalid" do
      it "rescues error and logs an error message" do
        monitor_url = "www.example.com"
        stub_const("ENV", "MONITOR_URL" => monitor_url)
        http_library = FakeHttpLibrary.new
        allow(http_library).to receive(:get).and_raise(ArgumentError, "invalid url")
        allow(Rails.logger).to receive(:error)
        log_message = "There was a problem with HTTP request to #{monitor_url}: invalid url"

        DependenciesCheckJob.perform_now(http_library)

        expect(Rails.logger).to have_received(:error).with(log_message)
      end
    end
  end

  context "when Monitor env is not set" do
    it "does not run the job and logs the missing env var" do
      stub_const("ENV", "MONITOR_URL" => nil)
      http_library = FakeHttpLibrary.new

      expect(http_library).to_not receive(:get)
      expect(Rails.logger).to receive(:error).with("ENV[\"MONITOR_URL\"] not set")

      DependenciesCheckJob.perform_now(http_library)
    end
  end
end
