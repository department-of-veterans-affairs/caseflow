class Hash
  def find_all_values_for(key)
    result = []
    result << self[key]

    self.values.each do |hash_value|
      values = [hash_value].flatten
      values.each do |value|
        result += value.find_all_values_for(key) if value.is_a? Hash
      end
    end
    result.compact
  end
end
