class Fakes::JudgeRepository
  def self.find_all_judges
    # Hard coding css IDs so we won't re-create users on each reload
    [
      User.find_or_create_by(css_id: "BVALHOWELL", station_id: "101", full_name: "Linda Howell"),
      User.find_or_create_by(css_id: "BVAAMACKEN", station_id: "101", full_name: "Andrew Mackenzie"),
      User.find_or_create_by(css_id: "BVAMELARKIN", station_id: "101", full_name: "Mary Larkin")
    ]
  end
end
