# frozen_string_literal: true

namespace :tags do
  desc "remove tags with no document associated with them"
  task detag: :environment do
    tags_to_remove = Tag.includes(:documents_tags).where(documents_tags: { tag_id: nil })

    if tags_to_remove.empty?
      puts "All tags are associated with Documents."
    else
      tags_to_remove.each do |tag|
        puts "Removing tag: #{tag.text}"
        tag.destroy
      end
      puts "Tags without associated documents have been removed."
    end
  end

  desc "merge tags where the differences are capitalization"
  task merge: :environment do
    tag_groups = Tag.all.group_by { |tag| tag.text.downcase }
    tag_groups.each do |_ ,tags|
      next if tags.length <= 1
      first_tag = tags.shift
      tags.each do |tag|
        unless first_tag.documents_tags.exists?(document_id: tag.documents.pluck(:id))
          first_tag.documents_tags << tag.documents_tags
        end
        tag.destroy
      end
    end
    puts "Tags with capitalization differences have been merged."
  end
end
