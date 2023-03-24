RSpec.describe "Reviews" do
  describe "resolve_multiple_reviews" do
    it "prints the expected output" do
      # create some test data
      veteran = create(:veteran, participant_id: "12345")
      hlrs = create_list(:higher_level_review, 2, veteran: veteran)
      scs = create_list(:supplemental_claim, 2, veteran: veteran)

      # set up the test environment
      allow(RequestStore).to receive(:[]).with(:current_user).and_return(
        OpenStruct.new(
          ip_address: '127.0.0.1',
          station_id: '283',
          css_id: 'CSFLOW',
          regional_office: 'DSUSER'
        )
      )

      # call the method we're testing
      output = capture(:stdout) do
        Reviews.resolve_duplicate_eps(hlrs + scs)
      end

      # assert that the expected output was printed
      expect(output).to include("| Veteran participant ID: 12345 | HigherLevelReview | Review ID: #{hlrs.first.id}")
      expect(output).to include("| Veteran participant ID: 12345 | HigherLevelReview | Review ID: #{hlrs.last.id}")
      expect(output).to include("| Veteran participant ID: 12345 | SupplementalClaim | Review ID: #{scs.first.id}")
      expect(output).to include("| Veteran participant ID: 12345 | SupplementalClaim | Review ID: #{scs.last.id}")
    end
  end
end
