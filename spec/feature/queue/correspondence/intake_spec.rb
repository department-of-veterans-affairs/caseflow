RSpec.feature('The Correspondence Intake page') do
  context "intake form shell" do
    it "the intake page exists" do
      correspondence_uuid = '123456789'
      visit "/correspondence/#{correspondence_uuid}/intake"
      expect current_path.to eq("/correspondence/123456789/intake")
    end
  end
end
