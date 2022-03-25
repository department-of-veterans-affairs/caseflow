# frozen_string_literal: true

# Executive Management Office inside Education

class EducationEmo < Organization
  def self.singleton
    EducationEmo.first || EducationEmo.create(name: "EXECUTIVE MANAGEMENT OFFICE", url: "edu-emo")
  end
end
