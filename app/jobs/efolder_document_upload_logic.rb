class EfolderDocumentUploadLogic


#1.Get Notifications table and join matching records Appeals
#and Legacy Appeals table that have notifications.

#def get_appeals_docs
#  if appeal has notifications and leagacy_appeals has notifications
#    if appeal == vbms_uploaded_documentation and legacy_appeals == vbms_uploaded_documentation
#      if latest_notification_date < lastest_vbms_uploaded_document and vbms_uploaded_document == "BVA Case Notifications" or !vbms_document;
#        return Appeal
#    end
#  end
#end

#appeals_id = 10

#gets the first 30 notifications and then create a hashmap(object) with appeals_id and appeals_type and notified_at
#Notification.first(30).map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}

#hashmap that finds the first 30 appeals notifications and gives back a hash map with the appeal id, appeal type and notified at datetime
#appeal_notification = Notification.first(30).map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}.last

#finds us an appeal that when passing the param of uuid or appeals id
#appeal = Appeal.find_by(uuid:appeal_notification[:appeals_id])||LegacyAppeal.find_by(vacols_id:appeal_notification[:appeals_id])

#gives all docs associated appeal veteran file number and has type BVA case notifications
#docs = VbmsUploadedDocument.where(appeal_id:appeal.id, appeal_type:appeal.class.name, document_type:"BVA Case Notifications")
#.order("uploaded_to_vbms_at DESC")

# = VbmsUploadedDocument.where()

#get a last notification asssociated with an appeal
#latest_notification_with_appeal = Notification.where(appeals_id:appeal_id).last

#if Appeal does not have a document, return appeal

#method checks if appeal has notifications


#def if_record_exist()
  #gets the first 30 notifications and then create a hashmap(object) with appeals_id and appeals_type and notified_at
  #Notification.first(30)
  #.map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}
  ##hashmap that finds the first 30 appeals notifications and gives back a hash map with the appeal id, appeal type and notified at datetime
  # appeal_notification = Notification.first(30)
  #.map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}
  #.last

  #finds us an appeal that when passing the param of uuid or appeals id
  #appeal = Appeal.find_by(uuid:appeal_notification[:appeals_id])||LegacyAppeal.find_by(vacols_id:appeal_notification[:appeals_id])

  #gives all docs associated appeal veteran file number and has type BVA case notifications
  #docs = VbmsUploadedDocument.where(appeal_id:appeal.id, appeal_type:appeal.class.name, document_type:"BVA Case Notifications")
  #.order("uploaded_to_vbms_at DESC")

  #get a last notification asssociated with an appeal
  #latest_notification_with_appeal = Notification.where(appeals_id:appeal_id).last

#end

  #def logic()
    #Todo
    #get all notifications
    #Notification.first(30).map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}
    #all_notification = Notification.first(30).pluck(:notified_at, :appeals_id)
    #check if appeal id matches  in vbms_upload_document table
    #Notification.first(30).each do |key, value|
      #puts "key: #{key} value: #{value}"
    #end

    #get a last notification asssociated with an appeal
    #latest_notification_with_appeal = Notification.where(appeals_id:appeal_id).last

    #return appeal that does not have a document with it
    #Notification.first(30).where('appeals_id NOT IN (SELECT DISTINCT(appeal_id) FROM VbmsUploadedDocument)')

  #end


  #finds us an appeal that when passing the param of uuid or appeals id
  def find_all_ama_appeals(appeals_id)

    appeal = Appeal.find_by(uuid:appeal_notification[:appeals_id])||LegacyAppeal.find_by(vacols_id:appeal_notification[:appeals_id])

  end

  def appeals_that_have_notifications

  #hashmap that finds the first 30 appeals notifications and gives back a hash map with the appeal id, appeal type and notified at datetime
    appeal_notification = Notification.first(30)
    .map{|n|{appeals_id:n.appeals_id, appeals_type:n.appeals_type, notified_at:n.notified_at}}

  end

  def check_if_record_exists_in_vbms_uploaded_doc?(appeal)
    #gives all docs associated appeal veteran file number and has type BVA case notifications
    docs = VbmsUploadedDocument.where(appeal_id:appeal.id, appeal_type:appeal.class.name, document_type:"BVA Case Notifications")
    docs.empty?
  end




end


