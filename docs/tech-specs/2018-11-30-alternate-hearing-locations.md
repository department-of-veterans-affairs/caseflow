This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Hearings/Hearing%20Schedule/Tech%20Specs/AlternateHearingLocations.md).

## Alternate Hearing Locations

Owner: Andrew Lomax
Date: 2018-11-30
Reviewer(s): Sharon Warner
Review by: 2018-11-30

## Context

A regional office (RO) sometimes schedules veterans at alternate hearing locations (AHL) because it's more convenient for the veteran. Previously, this scheduling was handled by staff at each regional office. AMA changed the scheduling tasks from the regional office to central office.

We have compiled a list of all alternate hearing locations for each RO and need to suggest an AHL to the hearing coordinators if there is a location that is closer to the veteran. These suggestions will need to be implemented in various ways on:
  - the Daily Docket
  - Schedule Veteran modal on Case Details View
  - Assign Hearings page

## Overview
[Research](https://github.com/department-of-veterans-affairs/caseflow/issues/7507)
[Facility Locator API](https://github.com/department-of-veterans-affairs/caseflow/issues/7545)

#### Necessary data
- Veteran's geolocation for their address (retrieved from Vet360 API)
- Veteran's RO + its alternate hearing location (stored in Caseflow)
- All options for alternate hearing locations for vet with distance to each (retrieved from Facility Locator API when passed veteran's geolocation and ID of all locations (RO + alternate hearing locations))

## Implementation

### Regional Office Data
 - On RegionalOffice model, add alternate_hearing_locations array for each RO with data that Meredith provided.
 - Store Central Office as alternate hearing location for MD, VA, and WVA?
  - if vet is closest to central, then veteran should show up in Central office RO on assign hearing page

### Veteran AHL Data
- On Veteran model add fetch the geolocation and the hearing location logic
`.hearing_locations` returns an array of locations in order of closest to furthest
- results will be cached in Redis for 45 days (veterans have to be scheduled at least 30 days in advanced ... could check average days in advanced a vet is scheduled + X)
```json
  <veteranId>: {
    "veteran_location": {
      "latlng": [0.0000, 0.0000],
      "address": "ABC123"
    },
    "hearing_locations": [
      {
        "distance": 0,
        "id": "ABC123",
        "address": "ABC123"
      }, ...
    ]
  }
```
- function checks if there has been a change in address and re-caches if not, and fetches new data if address has changes or Redis object does not exist

### Nightly Batch Job
- In a nightly batch (`app/jobs/schedule_alternate_hearing`) using Shoryuken, retrieve and cache info for each veteran.
```ruby
appeals.each do | appeal |
  appeal.veteran.hearing_locations
end
```
- this job is run for every veteran that can be scheduled for a hearing following these criteria:
  - **For Legacy:** Any veteran in location 57
  - **For AMA:** Any veteran with an assign hearing task
