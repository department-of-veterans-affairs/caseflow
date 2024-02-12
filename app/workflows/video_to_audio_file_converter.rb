# frozen_string_literal: true

require "streamio-ffmpeg"

class VideoToAudioFileConverter
  def initialize(video_path)
    @video_path = video_path
    @audio_path = video_path.gsub("mp4", "mp3")
  end

  def call
    return @audio_path if File.exist?(@audio_path)

    convert_to_mp3
  end

  def convert_to_mp3
    File.open(@audio_path, "w")
    @audio_path

    # movie = FFMPEG::Movie.new(@video_path)
    # movie.transcode
  end
end
