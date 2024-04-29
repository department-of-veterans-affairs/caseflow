# db/transcription_contractor_seeds.rb
module Seeds
  class TranscriptionContractor < Base
      # Create TranscriptionContractor records
    def seed!
      transcription_contractors = [
        { ame: "Genesis Government Solutions, Inc.", directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc." },
        { name: "Jamison Professional Services", directory: "BVA Hearing Transcripts/Jamison Professional Services" },
        { name: "The Ravens Group, Inc.", directory: "BVA Hearing Transcripts/The Ravens Group, Inc." }
      ]

      transcription_contractors.each do |contractor|
        ::TranscriptionContractor.find_or_create_by(
          name: contractor[:name],
          directory: contractor[:directory],
          is_available_for_work: false,
          previous_goal: 0,
          current_goal: 0
        )
      end
    end
  end
end
