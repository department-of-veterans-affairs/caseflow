class MpiTest
  attr_accessor :last_results

  def mpi
    @mpi ||= MPIService.new
  end

  def search_people(hash)
    results = mpi.client.people.search_people_info(hash)
    puts "\n\nFound #{results.count} search results"
    results.each do |res|
      puts
      print_patient(res[:registration_event][:subject1][:patient])
    end
    @last_results = results
    nil
  end

  def print_patient(hash)
    person = hash[:patient_person]
    [
      format_name(person),
      format_gender(person),
      format_ssn(person),
      format_status(hash),
      format_phone(person),
      format_birthtime(person),
      format_address(person),
    ].compact.each { |line| puts line }
  end

  def format_name(person)
    given_names = [person[:name][:given]].flatten.join(" ")
    "#{person[:name][:family]}, #{given_names}"
  end

  def format_status(hash)
    "Status: #{hash[:status_code][:@code]}"
  end

  def format_phone(person)
    value = person&.dig(:telecom, :@value)
    "Phone: #{value}" if value.present?
  end

  def format_gender(person)
    value = person&.dig(:administrative_gender_code, :@code)
    "Gender: #{value}" if value.present?
  end

  def format_ssn(person)
    other_ids = [person[:as_other_i_ds]].flatten
    ssns = other_ids.select { |other_id| other_id[:@class_code] == "SSN" }.map { |other_id| other_id.dig(:id, :@extension) }.compact
    "SSN: #{ssns[0]}" if ssns.any?
  end

  def format_birthtime(person)
    value = person&.dig(:birthtime, :@value)
    "Born: #{value}" if value.present?
  end

  def format_address(person)
    value = person&.dig(:addr)
    "Address: #{value[:street_address_line]}, #{value[:city]} #{value[:state]} #{value[:postal_code]}" if value.present?
  end
end
