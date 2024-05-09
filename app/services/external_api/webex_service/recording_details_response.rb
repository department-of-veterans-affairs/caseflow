# frozen_string_literal: true

class ExternalApi::WebexService::RecordingDetailsResponse < ExternalApi::WebexService::Response
  def mp4_link
    data["temporaryDirectDownloadLinks"]["recordingDownloadLink"]
  end

  def vtt_link
    data["temporaryDirectDownloadLinks"]["transcriptionDownloadLink"]
  end

  def mp3_link
    data["temporaryDirectDownloadLinks"]["audioDownloadLink"]
  end

  def topic
    data["topic"]
  end
end
