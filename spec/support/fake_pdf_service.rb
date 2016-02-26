class FakePdfService
  def self.save_pdf_for!(form8)
    @saved_form8 = form8
  end

  def self.output_location_for(_form8)
    File.join(Rails.root, "spec", "support", "form8-TEST.pdf")
  end

  class << self
    attr_reader :saved_form8
  end
end
