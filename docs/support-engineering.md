As we roll out Reader to 700 users, we've noticed some pain points in the way engineering and support communicate. This doc seeks to outline some ways in which we can more effectively collaborate.

# Motivations
1) As our products scale linearly, the amount of feedback we receive increases linearly. While pinging tech leads with 1-2 issues a week is manageable, pinging tech leads with 1-2 issues per day is not. This leads to a lot of context switching, and inevitably, difficulty prioritizing.
1) As we introduce new products it will be harder for support to retain context on all of them.
1) Questions around common user scenarios end up going to product or engineers, and often go without answers.

# Proposals
Below are three proposals for three different types of support tickets.
## FAQs - (User error)
The PMs and engineers will always have the most context on a given product. Support is not expected to know the answer to every user question. However, some questions are repeated many times. When support fields a question that they don't know the answer to, they will ping either the PM or engineer. If the problem is not a bug, but rather some user error, this problem and solution should be recorded in a centralized support-FAQ. On subsequent inquiries, support should reference the FAQ before pinging an engineer or product person. Over time this support-FAQ may migrate to our user help page FAQs.

## Creating or linking to engineering tickets - (Low Priority)
It's always difficult to disambiguate low priority from high priority. So we set the following standard, if only one user has sent in feedback on a specific issue then we treat it as low priority. Support should either find an existing ticket in the product repo (caseflow, caseflow-efolder, etc.) or they should make a new ticket in one of those repos. These tickets should be marked with the support label.

## Pinging tech leads - (High Priority)
If more than one user reports a bug, then we treat the issue as high priority. The tech lead should be notified so an investigation can start.

# Coordination
## Training
Support should receive regular training from product teams so that they understand products in depth. This will help them triage issues.

## Questions to ask users
Product teams should provide support with a list of questions to ask users. This may very between teams but will consist of something like:
- What is the file number?
- If the application is slow, are other VA services (like VBMS) slow?
