module Seeds
  class TranscriptionContractors < Base

    def seed!
      transcription_contractors = [
        { name: "The Ravens Group, Inc.",
          directory: "Ravens Pickup",
          poc: "Johnny Bravo",
          email: "theravensgroup@test.com",
          phone: "888-888-8888"},
        { name: "Very Real Contractors, Inc.",
          directory: "Very Pickup",
          poc: "Real Person",
          email: "veryrealcontractors@test.com",
          phone: "888-888-8888"},
        { name: "Genesis Government Solutions, Inc.",
          directory: "Genesis Pickup",
          poc: "John Doe",
          email: "genesisgovernmentsolutions@test.com",
          phone: "888-888-8888"},
        { name: "Jamison Professional Services",
          directory: "Jamison Pickup",
          poc: "Jane Doe",
          email: "jamisonprofessionalservices@test.com",
          phone: "888-888-8888"},
        { name: "Actual Contractor, Inc.",
          directory: "Actual Pickup",
          poc: "Johnny Cash",
          email: "actualcontractor@test.com",
          phone: "888-888-8888"},
        { name: "Vet Reporting",
          directory: "Vet Pickup",
          poc: "Johnny Cash",
          email: "vetreporting@test.com",
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
          phone: contractor[:phone],
        )
      end
    end
  end
end
