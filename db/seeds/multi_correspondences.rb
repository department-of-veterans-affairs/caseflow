# frozen_string_literal :true

# create correspondence seeds
module Seeds
  class MultiCorrespondences < Base
    def seed!
      create_correspondences_1
      create_correspondences_2
      create_correspondences_3
    end

    private

    def create_correspondences_1
      params = { first_name: "Adam", last_name: "West" }
      params[:file_number] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      params[:participant_id] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      veteran = create(
                  :veteran,
                  params)
      10.times do
        create(:correspondence,
               veteran_id: veteran.id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )
      end
    end

    def create_correspondences_2
      params = { first_name: "Michael", last_name: "Keaton" }
      params[:file_number] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      params[:participant_id] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      veteran = create(
                  :veteran,
                  params)
      8.times do
        create(:correspondence,
               veteran_id: veteran.id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )

      end
    end

    def create_correspondences_3
      params = { first_name: "Christian", last_name: "Bale" }
      params[:file_number] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      params[:participant_id] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      veteran = create(
                  :veteran,
                  params)
      25.times do
        create(:correspondence,
               veteran_id: veteran.id,
               source_type: "Mail",
               package_document_type_id: 10182,
               notes: "This is an example of notes for correspondence"
        )
      end
    end
  end
end
