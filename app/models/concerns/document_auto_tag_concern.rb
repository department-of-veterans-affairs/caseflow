module DocumentAutoTagConcern
  extend ActiveSupport::Concern

  private

  # Returns newly added tags
  def auto_tag_process
    new_tags = []
    begin
      puts "test"
      puts self.inspect
    rescue StandardError => error
      Rails.logger.error "#{err.message}\n#{err.backtrace.join("\n")}"
    end

    return new_tags
  end


  def add_auto_tags
    # get possible tags based on
    # doc_type_id
    # category_medical is true
    # category_other is true
    # category_procedural is true
    # TODO need to find 4th category criteria
    puts "doc_type_id #{doc_type_id}"
    puts "category_medical #{category_medical}"
    puts "category_other #{category_other}"
    puts "category_procedural #{category_procedural}"

  end
end
