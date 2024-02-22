# frozen_string_literal: true

describe Hearings::GetWebexRecordingsDetailsJob, type: :job do
  include ActiveJob::TestHelper
  let(:id) { "4f914b1dfe3c4d11a61730f18c0f5387" }
  # let(:mp4_link) { "https://site4-example.webex.com/nbr/MultiThreadDownloadServlet?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIUBSHkvL6Z5ddyBim5%2FHcJYcvn6IoXNEyCE2mAYQ5BlBg%3D%3D&timestamp=1567125236465&islogin=yes&isprevent=no&ispwd=yes" }
  # let(:mp3_link) { "https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAIXCIXsuBt%2BAgtK7WoQ2VhgeI608N4ZMIJ3vxQaQNZuLZA%3D%3D&timestamp=1567125236708&islogin=yes&isprevent=no&ispwd=yes&mediaType=1" }
  # let(:vtt_link) { "https://site4-example.webex.com/nbr/downloadMedia.do?siteid=2062842&recordid=305462&confid=137735449369118342&language=en_US&userid=3516472&serviceRecordID=305492&ticket=SDJTSwAAAAJVUJDxeA08qKkF%2FlxlSkDxuEFPwgGT0XW1z21NhY%2BCvg%3D%3D&timestamp=1567125236866&islogin=yes&isprevent=no&ispwd=yes&mediaType=2" }
  # let(:mp4_file_name) { "150000248290336_302_LegacyHearing-1.mp4" }

  subject { described_class.perform_now(id: id) }

  # it "hits the webex API and returns recording details" do
  #   expect(described_class.new(id: id).get_recording_details(id).mp4_link).to eq(mp4_link)
  #   expect(described_class.new(id: id).get_recording_details(id).mp3_link).to eq(mp3_link)
  #   expect(described_class.new(id: id).get_recording_details(id).vtt_link).to eq(vtt_link)
  # end

  it "names the file correctly" do
    # the issue is private vs public methods
    # should I make these methods public or
    # should I refactor tests to just make sure the method
    # is being called without the response from the method?
    # should_receive(:method) is the syntax
    # should we have some type of nil catch error if any of the api data comes back nil?
    # byebug
    # expect(subject).to have_received(:get_recording_details).exactly(3).times
    # :perform = spy
    # allow_any_instance_of(Hearings::GetWebexRecordingsDetailsJob)
    #   .to receive(:perform)
    #   .with(id: id)
    # Hearings::GetWebexRecordingsDetailsJob = spy
    # get_recording_details = spy
    # allow_any_instance_of(Hearings::GetWebexRecordingsDetailsJob)
    #   .to receive(:get_recording_details)
    #   .with(id)
    # allow_any_instance_of(Hearings::GetWebexRecordingsDetailsJob)
    #   .to receive(:perform)
    #   .with(id: id)
    allow_any_instance_of(Hearings::GetWebexRecordingsDetailsJob.perform_now(id: id))
      .to receive(:get_recording_details)
    # subject
    expect(Hearings::GetWebexRecordingsDetailsJob.perform_now(id: id)).to have_received(:get_recording_details).exactly(3).times

    # expect(subject).to have_received(:method).exactly(n).times.with(x).and_return(y)

  end

  context "job errors" do
    before do
      allow_any_instance_of(WebexService)
        .to receive(:get_recording_details)
        .and_raise(Caseflow::Error::WebexApiError.new(code: 400, message: "Fake Error"))
    end

    it "Successfully catches errors and adds to retry queue" do
      subject
      expect(enqueued_jobs.size).to eq(1)
    end

    it "retries and logs errors" do
      subject
      expect(Rails.logger).to receive(:error).with(/Retrying/)
      perform_enqueued_jobs { described_class.perform_later(id: id) }
    end
  end
end
