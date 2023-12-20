# Tech Spec: Find appellants in CorpDB (without a known relationship) using MPI

### Overview

When adding an appellant to an AMA appeal in Intake, Caseflow's current implementation is to fetch known relationships to the Veteran from CorpDB using BGS. This means that Caseflow is recording certain appellants as "unrecognized" when, in reality, they are just not recognized in a relationship to that particular Veteran. By using MPI (Master Person's Index) to search for a record of the appellant (regardless of Veteran relationship within CorpDB) we can reduce the amount of information Mail Intake users need to input and also reduce the number of appeals where Caseflow is a source of truth about the appellant's information. 

#### Services Involved
- BGS (Benefits Gateway Service): How Caseflow retrieves Veteran's known relationships
- CorpDB: Database where all known relationships are stored
- MPI (Master Person's Index): The authoritative source for Veteran, Beneficiary, Client, Employe, and other person type data

#### Relevant Stories/Epics
- [EPIC: Integrate with MPI as Source of Truth for Claimant/Appellant/Beneficiary Information](https://vajira.max.gov/browse/CASEFLOW-387)
- [EPIC: Find appellants in CorpDB (without a known relationship) using MPI](https://vajira.max.gov/browse/CASEFLOW-2147)
    - [Analyze the data structure XML for various MPI endpoints](https://vajira.max.gov/browse/CASEFLOW-2256)
    - [Create Caseflow Backend Service for making API calls to MPI](https://vajira.max.gov/browse/CASEFLOW-2272)
    - [Build a page to display data that will be retrieved from MPI](https://vajira.max.gov/browse/CASEFLOW-2255)
    - [Testing: Validate successful connection with the MPI SOAP API](https://vajira.max.gov/browse/CASEFLOW-2281)
    - [Create a fake implementation of MPI returning Data to Caseflow in the Back-End](https://vajira.max.gov/browse/CASEFLOW-2254)
    - [Ruby gem for handling SOAP communication with MPI](https://vajira.max.gov/browse/CASEFLOW-2271)

### Requirements and/or Acceptance Criteria

Caseflow allows staff to perform an enterprise search if the appellant, who is the requester of the decision review, cannot be located in CorpDB based upon the information provided via form 10182. 

The VA MPI integration touch points for the Caseflow integration are the following:
- 1305 Search Person (Attended, Returning Corresponding IDs) - Caseflow will perform a VA MPI Search Person (Attended Search) operation to obtain identity data and corresponding identifiers needed to locate information on an appellant.
- 1305 Retrieve Person (Returning Corresponding IDs with Relationships) - Caseflow will perform a VA MPI Retrieve Person operation to obtain the primary view associated with the identifier provided. 

#### 1305 Search Person Attended

Caseflow calls MPI’s **Search for Person (Attended)** Service to obtain MPI person records based on submitted traits. The MPI service performs a probabilistic trait-based search in the MPI data store and returns matches according to established business rules. Up to 10 possible matches can be returned by the service; if more than 10 records meet the minimum threshold, MPI returns a message indicating the search exceeded 10 records. MPI also returns all identifiers associated with the person record.

##### Integration Requirements

- Caseflow shall send a Search for Person (Attended, Returning Corresponding IDs) message to VA MPI.
- Caseflow shall include numerous traits or elements (parameters) that satisfies the criteria established in the Search Sample Scenarios Matrix in its search query to VA MPI. 
    - Last Name: Required
    - First Name
    - Middle Name
    - DOB
    - Gender
    - Address
- Caseflow shall have the capability to receive and process results of the Search for Person (Attended, Returning Corresponding IDs) request. A successful return message will include either a Primary View or Primary Views (up to 10), with each record including an ICN, or an indicator that no record was found. ICN (Integration Control Number) is the unique VA enterprise identifier used in MPI. The ICN is only being stored temporarily for use as an identifier when making the Retrieve Person request from VA MPI as part of a specific inquiry. VA MPI can return any of the following results:
    - VA MPI Unavailable
    - VA MPI Available:
        - Error
        - Successful

#### 1305 Retrieve Person using ICN Identifier

Caseflow calls MPI's **Retrieve Person using ICN Identifier** to obtain the Primary View associated with the identifier provided. Caseflow shall initiate the Retrieve Person Service using the ICN to obtain the Primary View Profile associated with the person record. Primary View (PV profile) provides a "gold" copy of person data. The PV Profile is referenced in VA information systems by an associated ICN
### Implementation

Implementing this service is going to involve writing code in two locations. The Caseflow repository (where this tech spec currently resides) and a seperate repository, which will be titled `ruby-mpi` and will live in the [VA Github](https://github.com/department-of-veterans-affairs). This gem will serves as a SOAP client to facilitate connection with MPI.

#### MPI Gem
##### File Structure

- lib folder
    - mpi folder
        - services folder
            - `person.rb`
                -   Methods to include
                    - Class method - `service_name` - This is how we will reference this service in the caseflow repo
                    - Instance method - `search_person_info(last_name:, first_name: nil, middle_name: nil, dob: nil, gender: nil, address: nil)` - Find up to 10 people who satisfy the search criteria provided in the parameters. The only parameter required by MPI for this request is `last_name`
                    - Instance method - `retrieve_person_info(icn)` - Request a PV profile record in MPI with the ICN that maps to the appropriate record
        - `base.rb`
            - Format the initialization of the Savon client
        - `error.rb`
            - Array of `TRANSIENT_ERRORS` returned from MPI
            - Array of `KNOWN_ERRORS` returned from MPI
        - `services.rb`
            - `require "mpi/services/person"`
    - `mpi.rb`
- spec folder
    - `base_spec.rb`
    - `errors_spec.rb`
    - `services_spec.rb`

MPI endpoints will live in this repo
#### Caseflow
##### Installing Gem in Caseflow

Add this line to Gemfile
```ruby
gem 'mpi', git: "https://github.com/department-of-veterans-affairs/ruby-mpi.git", ref: "latest-commit-hash"
```
It is important to include the most recent version of the repository in the `ref:` field here to ensure we are referencing the most current code. 

Execute:
```ruby
$ bundle install
```

Create mpi_service.rb file in `caseflow/app/services/external_api` and import gem
```ruby
require 'mpi'
```
##### Files to add in Caseflow

- A file titled `mpi_service.rb` will be added to `caseflow/app/services/external_api`. This file will create a new class `ExternalApi::MPIService`, which will include methods made available to the Caseflow client to make the necessary requests to the MPI service.
    - Methods to include:
        - `initialize` - Format our client proxy. Depending on if/what we end up caching, will create instance variables here to cache our requests. 
        - `search_person_info(last_name: '', first_name: nil, middle_name: nil, dob: nil, gender: nil, address: nil)` - Method to make 1305 request to "Search Person (Attended)" endpoint
        - `retrieve_person_info(icn)` - Method to make 1305 request to "Retrieve Person using ICN identifier" endpoint. Similar to `fetch_person_info(participant_id)` method in bgs_service.rb 

- Another file titled `mpi_service.rb` will be created, this time added to `caseflow/lib/fakes`. Here will exist a class `Fakes::MPIService`, which will serve back-end data mimicing the expected data returned from MPI. No tests are needed for this feature as this is a mock implementation and not meant for production. Development here will come down the road from PI9.

- An `mpi.rb` file added to `caseflow/config/initializers`, which will determine which MPI Service to use (Prod or Fakes)
### Open Questions

1. What data will we store, where will we store it, and how will we store it?
    - Cache PV profile records? We were told ICN should not be stored 
2. Should we make more parameters other than "Last name" required in the UI? Given that the MPI Database has over 40 million person records, and we can only receive a max of 10 people per request, how are we going to ensure users are able to make successful search requests while also maintaining current required information? 10182 form asks for Appellant's First name, Middle initial, last name, DOB, Preferred mailing address, preferred telephone number, preferred email. 
3. How are we initializing a request to CorpDB via BGS once we have received a Primary view record from MPI?