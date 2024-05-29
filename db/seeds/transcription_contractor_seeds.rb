module Seeds
  class TranscriptionContractor < Base

    def seed!
      transcription_contractors = [
        { name: "Genesis Government Solutions, Inc.",
          directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
          poc: "John Doe",
          email: "genesisgovernmentsolutions@test.com",
          phone: "888-888-8888"},
        { name: "Jamison Professional Services",
          directory: "BVA Hearing Transcripts/Jamison Professional Services",
          poc: "Jane Doe",
          email: "jamisonprofessionalservices@test.com",
          phone: "888-888-8888"},
        { name: "The Ravens Group, Inc.",
          directory: "BVA Hearing Transcripts/The Ravens Group, Inc.",
          poc: "Johnny Bravo",
          email: "theravensgroup@test.com",
          phone: "888-888-8888"}
      ]

      transcription_contractors.each do |contractor|
        ::TranscriptionContractor.find_or_create_by(
          name: contractor[:name],
          directory: contractor[:directory],
          is_available_for_work: false,
          previous_goal: 0,
          current_goal: 0,
          poc: contractor[:poc],
          email: contractor[:email],
          phone:contractor[:phone],
        )
      end
    end
  end
end

# TranscriptionContractor.create(name: "Genesis Government Solutions, Inc.",
#           directory: "BVA Hearing Transcripts/Genesis Government Solutions, Inc.",
#           poc: "John Doe",
#           email: "genesisgovernmentsolutions@test.com",
#           phone: "888-888-8888")

# TranscriptionContractor.create(name: "Jamison Professional Services",
#           directory: "BVA Hearing Transcripts/Jamison Professional Services",
#           poc: "Jane Doe",
#           email: "jamisonprofessionalservices@test.com",
#           phone: "888-888-8888")

# TranscriptionContractor.create(name: "The Ravens Group, Inc.",
#           directory: "BVA Hearing Transcripts/The Ravens Group, Inc.",
#           poc: "Johnny Bravo",
#           email: "theravensgroup@test.com",
#           phone: "888-888-8888")
