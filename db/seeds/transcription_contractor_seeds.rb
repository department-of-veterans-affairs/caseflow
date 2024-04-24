# db/transcription_contractor_seeds.rb
module Seeds
  class TranscriptionContractor < Base
      # Create TranscriptionContractor records
    def seed!
      transcription_contractors = [
        { qat_name: "Genesis Government Solutions, Inc.", qat_directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc." },
        { qat_name: "Jamison Professional Services", qat_directory: "BVA Hearing Transcripts/Jamison Professional Services" },
        { qat_name: "The Ravens Group, Inc.", qat_directory: "BVA Hearing Transcripts/The Ravens Group, Inc." }
      ]

      transcription_contractors.each do |contractor|
        ::TranscriptionContractor.find_or_create_by(
          qat_name: contractor[:qat_name],
          qat_directory: contractor[:qat_directory],
          qat_stop: false,
          previous_goal: 0,
          current_goal: 0
        )
      end
    end
  end
end
