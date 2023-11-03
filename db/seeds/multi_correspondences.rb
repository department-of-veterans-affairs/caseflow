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
      uuid = "9ae80f64-6e9a-41cc-b28b-9557745fc0f6"
      params = { first_name: "Adam", last_name: "West" }
      params[:file_number] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      params[:participant_id] = 66_555_444 unless Veteran.find_by(file_number: 66_555_444)
      veteran = create(
                  :veteran,
                  params)
      create_const_correspondence(veteran, uuid)
      20.times do
        create_default_correspondence(veteran)
      end
    end

    def create_correspondences_2
      uuid = "f1c9c38e-884e-4d74-82b0-7536eb11d2d3"
      params = { first_name: "Michael", last_name: "Keaton" }
      params[:file_number] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      params[:participant_id] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      veteran = create(
                  :veteran,
                  params)
      create_const_correspondence(veteran, uuid)
      8.times do
        create_default_correspondence(veteran)
      end
    end

    def create_correspondences_3
      uuid = "9d912a08-7847-436f-9c58-bdf3896be2f1"
      params = { first_name: "Christian", last_name: "Bale" }
      params[:file_number] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      params[:participant_id] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      veteran = create(
                  :veteran,
                  params)
      create_const_correspondence(veteran, uuid)
      100.times do
        create_default_correspondence(veteran)
      end
    end

    def create_default_correspondence(veteran)
      create(:correspondence,
        veteran_id: veteran.id,
        source_type: "Mail",
        package_document_type_id: 10182,
        notes: "This is an example of notes for correspondence"
      )
    end

    def create_const_correspondence(veteran, uuid)
      create(:correspondence,
        veteran_id: veteran.id,
        source_type: "Mail",
        package_document_type_id: 10182,
        notes: "This is an example of notes for correspondence",
        uuid: uuid
      )
    end
  end
end
