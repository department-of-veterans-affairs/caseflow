class PersistForm8Data < ActiveRecord::Migration
  def change
    # We're adding a table to store the Form 8 data for later analysis.
    # Fields that can be modified before certification have counterparts
    # prefixed by "_initial". We want this to do analysis on what fields
    # users manually edit.
    # TODO(alex): commented out fields are commented out because we don't
    # appear to prepopulate them (see from_appeal in form8.rb)
    create_table :form8s do |t|
      t.belongs_to :certification, index: true
      t.integer :certification_id
      t.string :vacols_id     # ID in VACOLS DB - not user modifiable
      t.string :appellant_name # Person appealing distinct from veteran
      t.string :appellant_relationship # Relationship to veteran
      t.string :file_number #ID in VBMS? - not user modifiable
      t.string :veteran_name # FirstName LastName
      t.string :insurance_loan_number
      t.text :service_connection_for # How the claim is connected to service record
      t.date :service_connection_notification_date
      t.text :increased_rating_for
      t.date :increased_rating_notification_date
      t.text :other_for
      t.date :other_notification_date
      t.string :representative_name
      t.string :representative_type # TODO make this an enum ["Attorney" "Agent" "Organization" "Other"]
      t.string :representative_type_specify_other
      t.string :power_of_attorney # TODO make this an enum certification that valid POA is in another VA file
      t.string :power_of_attorney_file
      t.string :agent_accredited
      t.string :form_646_of_record # TODO cast to boolean
      t.string :form_646_not_of_record_explanation
      t.string :hearing_requested # TODO make this an enum
      t.string :hearing_held # TODO cast to boolean
      t.string :hearing_transcript_on_file # TODO cast to boolean
      t.string :hearing_requested_explanation
      t.string :contested_claims_procedures_applicable # TODO cast to boolean
      t.string :contested_claims_requirements_followed # TODO cast to boolean
      t.date :soc_date
      t.string :ssoc_required # TODO make this an enum  "Required and furnished"/"Not required"
      t.text :record_other_explanation, array: true # One or more from a list of records to send to Veteran's Appeals
      t.text :remarks
      t.string :certifying_office # Not user-modifiable
      t.string :certifying_username # Not user-modifiable
      t.string :certifying_official_name
      t.string :certifying_official_title
      t.date :certification_date # Not user-modifiable

      # Fields representing record types to be forwarded
      # to the Board of Veteran's Appeals. These are all integers
      # mostly for compatibility with code that existed before this
      # migration.
      t.string :record_cf_or_xcf
      t.string :record_inactive_cf
      t.string :record_dental_f
      t.string :record_r_and_e_f
      t.string :record_training_sub_f
      t.string :record_loan_guar_f
      t.string :record_outpatient_f
      t.string :record_hospital_cor
      t.string :record_clinical_rec
      t.string :record_x_rays
      t.string :record_slides
      t.string :record_tissue_blocks
      t.string :record_dep_ed_f
      t.string :record_insurance_f
      t.string :record_other

      # initial field values, stored for data analysis
      t.string :_initial_appellant_name
      t.string :_initial_appellant_relationship
      t.string :_initial_veteran_name
      t.string :_initial_insurance_loan_number
      t.date :_initial_service_connection_notification_date
      t.date :_initial_increased_rating_notification_date
      t.date :_initial_other_notification_date
      t.date :_initial_soc_date
      t.string :_initial_representative_name
      t.string :_initial_representative_type
      t.string :_initial_hearing_requested
      t.string :_initial_ssoc_required
    end
  end
end
