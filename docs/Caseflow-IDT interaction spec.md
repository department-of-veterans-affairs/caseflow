# Overview

The Interactive Decision Template (IDT), introduced this year, is a Word macro that assists attorneys, judges, and BVA dispatch with decision processing. It aims to improves attorney experience in numerous ways, including storing snippets of decisions for reuse and prefilling a Word doc with decision data.

Since attorney/judge productivity is a significant part of appeals processing throughput, we need to ensure that each feature in the IDT is supported for AMA appeals.

In particular, Paul Saindon expressed his hope that we have a solution for BVA dispatch by the RAMP appeal processing milestone in October.

Changes are needed to the current IDT, since AMA appeals will not be stored in VACOLS, so the IDT will need to be able to fetch data from Caseflow for AMA appeals.

We have two main goals when developing our IDT interactions:
- Reduce the technical complexity of the IDT by providing one secure interface for the IDT to obtain both AMA and legacy appeal data
	- Where possible, we can leverage this effort to support the next version of Appeals Status, which will need to support AMA appeals by February 14th, 2019.
- Create smooth interactions between Caseflow and the IDT that save users from having to go to VACOLS and continue the transition to a Caseflow UI-only world

We can break this effort down into a few pieces:

- Authentication
- Attorney functionality
- BVA dispatch functionality

This document describes only what we plan to do by October 1st, 2019 to support RAMP appeals.


## Authentication

The IDT needs access to appeal information and thus needs to authenticate with Caseflow with a particular CSS ID for Caseflow to securely pass it information via the API. The IDT has the ability to make HTTP requests directly from the IDT, and to open pages in a web browser. However, the IDT can't receive the results of requests made in a web browser. Tokens should not be passed [in URLS]( https://www.fullcontact.com/blog/never-put-secrets-urls-query-parameters/) for various reasons. 

One viable approach is to require users to periodically copy a token from Caseflow into the IDT (here, we assume that tokens are valid for 3 days, but potentially longer or shorter is better).

### Draft of login flow

1. User launches IDT. 
1. If there is a token saved for the user, IDT attempts to use it to make the neccessary API call.
1. If there is no token, or if a 403 status code is returned by the API (token expired), IDT makes a GET request to caseflow.ds.va.gov/idt/api/v1/token
1. Caseflow returns a proposed token and a one-time key.
1. IDT opens a browser window with the URL caseflow.ds.va.gov/idt/auth?key=#{ONE_TIME_KEY}
1. If the user is not logged in, Caseflow's existing logic will redirect the user to the CSS login page, and redirect back to caseflow.ds.va.gov/idt/auth?key=#{ONE_TIME_KEY} after login.
1. After the user is logged in, Caseflow will mark the token as valid and display a message like "You have successfully authenticated with the IDT. You can now return to the IDT"
1. In the meantime, every 10 seconds, the IDT will make a new call with the proposed token. If the token is not yet validated, Caseflow will return a 401. Otherwise, Caseflow will return a 200.
1. The user can use the IDT without having to log in again until the token is no longer valid.

### Token implementation

Option 1: JWTs

Using a library like [ruby-jwt](https://github.com/jwt/ruby-jwt), we create digitally signed tokens that contain the CSS ID of the user so we can later verify access. These tokens do not have to be persisted anywhere.

Pros: Stateless, common best practice

Cons: Implementation is likely more complex than the other option, more overhead for devs to understand. 

Option 2: Generate UUID & cache it in Redis with expiration time

With this approach, we'd store a UUID and associate it with a CSS ID in Redis. By setting the expiration time equal to our token validity window, we'd just need to check for presence of the token in Redis/CSS ID to check validity. 

Pros: Simple implementation

Cons: Dependency on Redis — a Redis outage takes down the IDT API

## Attorney functionality

The IDT needs to be able to fetch appeals in two ways: 
- Appeals currently assigned to a attorney with CSS ID
- Activated appeals for a veteran from Veteran ID.

We can accommodate both types of requests by accepting a CSS ID as a query parameter
or the veteran ID (SSN/C-number) as a header.

`GET /api/idt/v1/appeals?assigned_to=BVAPROKOP`
or 
`GET /api/idt/v1/appeals -H veteran_id`

Here's a list of the pieces of data we'll provide for each appeal.

- Appellant name
- Veteran name if different
- Claim number (SS or C number)
- Docket number
- Representative name and type 
- number of issues
- Name of the judge that assigned the case
- Issues
    - Program, areas, etc
    - Free text

For BVA dispatch functionality to work properly, the IDT should save the RAMP appeal id in metadata.

## BVA dispatch functionality

Eventually, we will unify the BVA dispatch process for both legacy appeals and AMA appeals. However, due to limited bandwidth, by October 1st we believe Caseflow will only have the ability to support the BVA Dispatch IDT for RAMP appeals.

One option would be to to work with the board to have 2 specific BVA Dispatch team members handle all RAMP appeals. All other BVA Dispatch team members would continue to use the IDT as is for now.

The BVA Dispatch team members would use Caseflow to view their tasks. Currently, the BVA Dispatch IDT has a queue-like view. For RAMP appeals, we propose that Caseflow provides a queue interface— Caseflow currently provides a queue interface for attorneys, judges, and soon co-located. For each item in a BVA Dispatch user's queue, the user could be able to find the document ID, then open the document in the BVA dispatch drive.

When the user opens the document, we'll read the RAMP appeal id from the document metadata and make a call to the API for the following information.

`GET /api/idt/v1/appeals/:appeal_id/dispatch_addresses`

This endpoint will return the following data:

- Appellant 
    - Full name
    - Address
- POA
    - Name
    - Address


Caseflow hasn't yet settled on a full plan for handling the following pieces of data. It's possible that we'll need some temporary workaround for RAMP appeals— TBD.

- Contesting claimants
	- Full names
	- Addresses

- Interested members of Congress
	- Full names
	- Addresses

## Rollout plan (tentative)

Even though we're working toward an October 1st deadline, we can develop, test, and launch much of the new functionality before that deadline. We propose that we complete 1. and 2. as development schedules allow, well in advance of the October 1st deadline.

1. Develop authentication piece and test that the IDT is able to obtain a valid token.
2. Develop Caseflow IDT API endpoints to fetch appeal information for attorneys for VACOLS appeals, transition IDT to using that functionality.
3. Add RAMP appeal support to Caseflow IDT API endpoints for attorneys.
4. Develop RAMP-only BVA dispatch view.
5. Develop Caseflow IDT API endpoints for BVA dispatch.

### TODO
- Create more detailed spec of expected API responses
