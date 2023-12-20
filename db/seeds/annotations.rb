# frozen_string_literal: true

# create annotation seeds

module Seeds
  class Annotations
    def seed!
      create_annotations
    end

    private

    def create_annotations
      Generators::Annotation.create(comment: "Hello World!", document_id: 1, x: 300, y: 400)
      Generators::Annotation.create(comment: "This is an example comment", document_id: 2)
    end
  end
end
