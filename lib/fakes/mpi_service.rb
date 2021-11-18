# frozen_string_literal: true

class Fakes::MPIService
  def search_people_info(last_name:, first_name: nil, middle_name: nil,
                         ssn: nil, date_of_birth: nil, gender: nil, address: nil, telephone: nil)
    [{:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028056V759470^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005638^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "I"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930126"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014691", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005638^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"BOISE", :state=>"ID", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"100"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028054V494652^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005636^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "G"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014689", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005636^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"MARIETTA", :state=>"GA", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>
             {:@code=>"EMP~HPT~VET",
              :"@xsi:type"=>"CD",
              :@display_name=>"Employee, Unknown, Veteran"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028049V170427^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005631^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "B"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014684", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005631^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"WALNUT CREEK", :state=>"CA", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>{:@code=>"EMP~PAT", :"@xsi:type"=>"CD", :@display_name=>"Employee, Patient"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028050V275598^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005632^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "C"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014685", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005632^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"SALEM", :state=>"MA", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>{:@code=>"EMP~VET", :"@xsi:type"=>"CD", :@display_name=>"Employee, Veteran"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028052V102835^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005634^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "E"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014687", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005634^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"KENOSHA", :state=>"WI", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>
             {:@code=>"CON~EMP~VET",
              :"@xsi:type"=>"CD",
              :@display_name=>"Contractor, Employee, Veteran"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028051V040983^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005633^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "D"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014686", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005633^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"TOLEDO", :state=>"OH", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>{:@code=>"EMP", :"@xsi:type"=>"CD", :@display_name=>"Employee"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028048V015105^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005630^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"0000001200028048V015105000000^PI^200ESR^USVHA^A",
           :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"627014683^PI^200BRLS^USVBA^A", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"32436762^PI^200CORP^USVBA^A", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"2021091518^EI^200HRS^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>
           [{:given=>["MADISON", "ANNE"], :family=>"WESTBROOK", :@use=>"L"},
            {:family=>"GRANGER", :@use=>"C"}],
          :telecom=>{:@use=>"HP", :@value=>"(555)463-1987"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930114"},
          :multiple_birth_ind=>{:@value=>"false"},
          :addr=>
           {:street_address_line=>"3318 GONDAR AVENUE",
            :city=>"LONG BEACH",
            :state=>"CA",
            :postal_code=>"90808",
            :country=>"USA",
            :@use=>"PHYS"},
          :as_other_i_ds=>
           {:id=>{:@extension=>"627014683", :@root=>"2.16.840.1.113883.4.1"},
            :status_code=>{:@code=>"4"},
            :scoping_organization=>
             {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
              :@class_code=>"ORG",
              :@determiner_code=>"INSTANCE"},
            :@class_code=>"SSN"},
          :birth_place=>{:addr=>{:city=>"CERRITOS", :state=>"CA", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"151"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>
             {:@code=>"EMP~PAT~VET",
              :"@xsi:type"=>"CD",
              :@display_name=>"Employee, Patient, Veteran"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028053V386767^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005635^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "F"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930125"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014688", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005635^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"ORLANDO", :state=>"FL", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"135"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>{:@code=>"EMP~HPT", :"@xsi:type"=>"CD", :@display_name=>"Employee, Unknown"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200028055V623111^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005637^PN^200EDR^USDVA^PCE", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>{:given=>["MADISON", "H"], :family=>"WESTBROOK", :@use=>"L"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930126"},
          :as_other_i_ds=>
           [{:id=>{:@extension=>"627014690", :@root=>"2.16.840.1.113883.4.1"},
             :status_code=>{:@code=>"4"},
             :scoping_organization=>
              {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"SSN"},
            {:id=>{:@extension=>"6005637^PN^200EDR^USDVA^PCE", :@root=>"2.16.840.1.113883.4.349"},
             :scoping_organization=>
              {:id=>{:@root=>"2.16.840.1.113883.4.349"},
               :@class_code=>"ORG",
               :@determiner_code=>"INSTANCE"},
             :@class_code=>"PAT"}],
          :birth_place=>{:addr=>{:city=>"ALBANY", :state=>"NY", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"100"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"},
 {:registration_event=>
   {:id=>{:@null_flavor=>"NA"},
    :status_code=>{:@code=>"active"},
    :subject1=>
     {:patient=>
       {:id=>
         [{:@extension=>"1200047905V909525^NI^200M^USVHA^P", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"627014682^PI^200BRLS^USVBA^A", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"32437994^PI^200CORP^USVBA^A", :@root=>"2.16.840.1.113883.4.349"},
          {:@extension=>"6005629^PN^200EDR^USDVA^A", :@root=>"2.16.840.1.113883.4.349"}],
        :status_code=>{:@code=>"active"},
        :patient_person=>
         {:name=>
           [{:given=>["MADISON", "ANNA"], :family=>"WESTBROOK", :@use=>"L"},
            {:family=>"FARNSWORTH", :@use=>"C"}],
          :telecom=>{:@use=>"HP", :@value=>"(555)496-8237"},
          :administrative_gender_code=>{:@code=>"F"},
          :birth_time=>{:@value=>"19930113"},
          :multiple_birth_ind=>{:@value=>"false"},
          :addr=>
           {:street_address_line=>"4958 Pearce Ave",
            :city=>"Lakewood",
            :state=>"CA",
            :postal_code=>"90712",
            :country=>"USA",
            :@use=>"PHYS"},
          :as_other_i_ds=>
           {:id=>{:@extension=>"627014682", :@root=>"2.16.840.1.113883.4.1"},
            :status_code=>{:@code=>"4"},
            :scoping_organization=>
             {:id=>{:@root=>"1.2.840.114350.1.13.99997.2.3412"},
              :@class_code=>"ORG",
              :@determiner_code=>"INSTANCE"},
            :@class_code=>"SSN"},
          :birth_place=>{:addr=>{:city=>"ARTESIA", :state=>"CA", :country=>"USA"}}},
        :subject_of1=>
         {:query_match_observation=>
           {:code=>{:@code=>"IHE_PDQ"},
            :value=>{:"@xsi:type"=>"INT", :@value=>"142"},
            :@class_code=>"COND",
            :@mood_code=>"EVN"}},
        :subject_of2=>
         {:administrative_observation=>
           {:code=>
             {:@code=>"PERSON_TYPE",
              :@code_system=>"2.16.840.1.113883.4.349",
              :@display_name=>"Person Type"},
            :value=>
             {:@code=>"EMP~PAT~VET",
              :"@xsi:type"=>"CD",
              :@display_name=>"Employee, Patient, Veteran"},
            :@class_code=>"VERIF"},
          :@type_code=>"SBJ"},
        :@class_code=>"PAT"},
      :@type_code=>"SBJ"},
    :custodian=>
     {:assigned_entity=>{:id=>{:@root=>"2.16.840.1.113883.4.349"}, :@class_code=>"ASSIGNED"},
      :@type_code=>"CST"},
    :@class_code=>"REG",
    :@mood_code=>"EVN"},
  :@type_code=>"SUBJ"}]
  end
end
