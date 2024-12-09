# frozen_string_literal: true

# Taken from the following:
# https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver

module DownloadHelpers
  TIMEOUT = 60
  WORKDIR = Rails.root.join("tmp/downloads_#{ENV['TEST_SUBCATEGORY'] || 'all'}").to_s

  module_function

  def downloads
    Dir.entries(WORKDIR)
      .reject { |f| f == "." || f == ".." }
      .map { |file| File.join(WORKDIR, file) }
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.part$/).any?
  end

  def clear_downloads
    FileUtils.rm_rf(Dir.glob(File.join(WORKDIR, "*")))
  end

  def latest_download
    downloads.max_by { |file| File.mtime(file) }
  end

  def download_csv
    wait_for_download
    CSV.read(latest_download)
  end
end
