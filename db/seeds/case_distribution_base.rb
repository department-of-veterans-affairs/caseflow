module Seeds
  class CaseDistributionBase
    def create_veteran(options = {})
      params = {
        file_number: format("%<n>09d", n: options[:file_number]),
        participant_id: format("%<n>09d", n: options[:participant_id])
      }
      create(:veteran, params.merge(options))
    end

    def find_veteran(file_number)
      Veteran.find_by(file_number: format("%<n>09d", n: file_number + 1))
    end
  end
end
