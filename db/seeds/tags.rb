module Seeds
  class Tags
    def seed!
      create_tags
    end

    private

    def create_tags
      DocumentsTag.create(
        tag_id: Generators::Tag.create(text: "Service Connected").id,
        document_id: 1
      )
      DocumentsTag.create(
        tag_id: Generators::Tag.create(text: "Right Knee").id,
        document_id: 2
      )
    end
  end
end
