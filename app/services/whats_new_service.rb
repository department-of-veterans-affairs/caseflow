class WhatsNewService
  def self.determine_version
    update_contents = File.read("app/views/whats_new/show.html.erb")
    update_contents.hash.to_s
  end

  def self.version
    @version ||= WhatsNewService.determine_version
  end
end