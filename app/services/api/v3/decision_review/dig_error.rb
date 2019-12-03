class Api::V3::DecisionReview::DigError
  def initialize(hash:, path:, values:)
    @hash = hash
    @path = path
    @values = values
    raise "hash must have method 'dig'" unless @hash.respond_to? :dig
    raise "path must be an array" unless @path.is_a? Array
    raise "values must be an array" unless @values.is_a? Array
  end

  def to_s 
    return nil if path_is_valid_for_hash?

    this_path = PathString.new @path
    one_of_these = ValuesString.new @values
    got_this_instead = value_at_path_sentence

    "#{this_path} should be #{one_of_these}. #{got_this_instead}."
  end

  class Quoted
    attr_reader :to_s

    def initialize(value)
      @to_s = case value
       when String
         "\"#{value}\""
       when nil
         "nil"
       else
         value.to_s
       end
    end
  end

  class PathString
    def initialize(path)
      @path = path
    end
  
    def to_s
      @path.map { |node| "[#{Quoted.new node}]" }.join
    end
  end
  
  class ValuesString
    def initialize(values)
      @values = values
    end
  
    def to_s
      @values.length == 1 ? first_to_s : "one of #{@values}"
    end
  
    private

    def first
      @values.first
    end
  
    def first_to_s
      return "a(n) #{first.name.downcase}" if first.class == Class

      "#{Quoted.new first}"
    end
  end

  private

  def value_at_path
    @hash.dig *@path
  end

  def value_at_path_sentence
    "Got: #{Quoted.new value_at_path}"
  rescue
    "Invalid path"
  end

  def path_is_valid_for_hash?
    @values.any? { |value| value === value_at_path }
  rescue
    false
  end

end
