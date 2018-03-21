Running Caseflow connected to FACOLS is [well documented in the README](https://github.com/department-of-veterans-affairs/caseflow/blob/master/README.md). This document explains more advanced FACOLS usage. Specifically:
1) How to add new cases to FACOLS
1) How to add new tables to FACOLS
   1) How sanitizaiton of data works

# Adding new cases to FACOLS
We check FACOLS data directly into GitHub since the data has been scrubbed of any PII. The test data comes from the RDS instance named: `dsva-appeals-vacols-uat-datasource-2017-12-13-11-20`. This is a copy of UAT from December 2017 which means that it contains PII. We pull a subset of the data from this RDS instance, sanitize it, and dump it to CSV files that we check into `local/vacols`. The master list of cases in FACOLS is maintained in `local/vacols/cases.csv`. Here is an example excerpt from the file:

|vacols_id|vbms_id|bgs_id|used_in_app|comments|
|---|---|---|---|---|
|3575931|static_documents||reader queue|Case assigned to attorney|
|3619838|no_categories||reader queue|Case assigned to attorney|
|3625593|random_documents||reader queue|Case assigned to attorney|

- `vacols_id`
   - This column represents the `bfkey` from the `brieff` table.
   - This is just a DB primary key and so is not considered PII.
- `vbms_id`
   - Currently used to specify which documents we want to associate with this case. The choices are `static_documents`, `no_categories`, `random_documents`, `redacted_documents`.
   - In the future this field will be used to coordinate how this case associates with fake VBMS data.
- `bgs_id`
   - Currently not used, but this field will have an analogous purpose to `vbms_id`.
- `used_in_app`
   - A list of which apps rely on this case.
   - If you no longer need a case, remove the app from this list.
   - If no apps are using it, it's safe to remove this row from the CSV.
   - If you start using a case, add your app's name to this list so no one else removes it from the list.
- `comments`
   - Anything you'd like to add to give this case context.

To add a new case:
1) Add a row to this above CSV.
   - To find a relevant `vacols_id` to use, you can run the rails console in the `ssh_forwarding` environment. This will enable you connect to the datasource RDS instance to peruse the available data. Instructions of connecting can be found [here](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/how-to-setup-ssh-port-forwarding.md). 
   - The ssh command to run to connect to the datasource RDS instance is: `ssh -L 1526:dsva-appeals-vacols-uat-datasource-2017-12-13-11-20.cdqbofmbcmtd.us-gov-west-1.rds.amazonaws.com:1526 <Your UAT jumpbox ssh config>`.
   - The username and password for the datasource RDS instance is in [credstash](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/master/docs/credstash.md)
   ```
   -export VACOLS_USERNAME=<FACOLS credentials username>	+export VACOLS_USERNAME=`credstash -t appeals-credstash get vacols.facols.db_username`
   -export VACOLS_PASSWORD=<FACOLS credentials password>	+export VACOLS_PASSWORD=`credstash -t appeals-credstash get vacols.facols.db_password`
   ```
   - Once connected, you can run any queries you want to find useful cases, then get their `bfkey`s from the `brieff` table and copy them into the `cases.csv` file.
1) Run the following to retrieve all the data for the cases you added:
   ```
   RAILS_ENV=ssh_forwarding rake local:vacols:dump_data
   ```
   - This will dump data into the relevant CSV files in `local/vacols` so they can be imported later into FACOLS.
   - When this finishes running, you might (but are unlikely to) see red-text explaining that there may be PII in the data you pulled. If this is the case, we may need to white-list or fake out another field. Coordinate with Mark and Chris to make this happen.
1) Run the following to import the dumped data into FACOLS:
   ```
   RAILS_ENV=local rake local:vacols:seed
   ```
1) Check in the resulting changes to the dumped-data CSVs.


This will seed FACOLS with the new data. Note when seeding data, all date-time fields are date shifted as if today was November, 1, 2017. In this way we can keep even old data current. After this you should be good to go! Note all PII will be sanitized, and staff ids will be scrambled, but you can backtrack any necessary information from the bfkey which stays the same.

# Adding new tables to FACOLS
When adding a new table you must add code to sanitize any potential PII. Unfortunately, adding a new table is somewhat complicated, and if done incorrectly may leak PII, so please pair with either Mark or Chris on this process. 

1) Every table we add must have a wrapper class just like `VACOLS::Case` that defines the table for active record. Once that's established there are two different procedures to add two different types of tables.

   1) Adding a table that is related to the `brieff` table. For example, the `hearsched` table belongs to the brieff table. For these tables, we pull in rows that relate to the cases specified in the `cases.csv` file. To add the table, you'll need to add two things to the `local:vacols:dump_data` rake task defined in `vacols.rake`.
      1) Although technically optional, to reduce the number of queries you can add the table to the `VACOLS::Case.includes` statement.
      1) Add a line similar to `write_csv(VACOLS::CaseHearing, cases.map(&:case_hearings), sanitizer)`. This writes the data from each `case_hearings` row that corresponds to a given `case`.
   2) Adding a table that is not related to the `brieff` table. For example the `staff` table has all the BVA staff members in it. For these kinds of tables, we must select which rows to bring in. What you choose depends on the use case. Some tables are completely dumped, while in others we only dump certain rows. Look at how we dump the `tbsched` table for reference:
      ```
      write_csv(
         VACOLS::TravelBoardSchedule,
         VACOLS::TravelBoardSchedule.where("tbyear > 2016"),
         sanitizer
      )
      ```
   
1) Sanitize the data. The `write_csv` function takes in a `sanitizer` object. This sanitizer is defined in `sanitizers.rb`. In `write_csv` we call a `sanitize` method which uses meta-programming to call two methods specific to the class we're sanitizing:
   1) `white_list_#{lower_case_class_name}`: This method must return a string array of a set of fields to white list. All other fields are immediately nilled out. This is to ensure we don't actually write a field we do not intend to.
   1) `sanitize_#{lower_case_class_name}`: This allows us to fake out fields that were or were not white listed. If either of these methods are not defined, then sanitization will fail.

1) Dump and seed the data:
   ```
   RAILS_ENV=ssh_forwarding rake local:vacols:dump_data
   RAILS_ENV=local rake local:vacols:seed
   ```
1) Check the resulting CSV updates into git.
1) Whitelist fields with detected PII. When sanitization is run, we examine all white-listed fields for PII, including emails, phone numbers, sentences, and vet ids. If any field matches any of these RegExs then we print it in red at the end of the dump data job. This can alert you to a possible leak. To respond, you should either, stop white-listing the field if it is actually PII, or add the field to a special white-list for fields that detect PII but don't actually contain it. This white-list is in the `ignore_pii_in_fields` method.
