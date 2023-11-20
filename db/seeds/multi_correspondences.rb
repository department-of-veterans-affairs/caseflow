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
      32.times do
        create(:appeal, veteran_file_number: veteran.file_number)
      end
      20.times do
        create_default_correspondence(veteran)
      end
    end

    def create_correspondences_2
      params = { first_name: "Michael", last_name: "Keaton" }
      params[:file_number] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      params[:participant_id] = 67_555_444 unless Veteran.find_by(file_number: 67_555_444)
      veteran = create(
                  :veteran,
                  params)
      13.times do
        create(:appeal, veteran_file_number: veteran.file_number)
      end
      30.times do
        create_default_correspondence(veteran)
      end
    end

    def create_correspondences_3
      params = { first_name: "Christian", last_name: "Bale" }
      params[:file_number] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      params[:participant_id] = 68_555_444 unless Veteran.find_by(file_number: 68_555_444)
      veteran = create(
                  :veteran,
                  params)
      7.times do
        create(:appeal, veteran_file_number: veteran.file_number)
      end
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
  end
end
