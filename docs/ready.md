# Readiness Checklists

This is being piloted by the Whiskey team.

## Checklists

### Ready For Dev
Acceptance criteria includes handling for the following (or explicitly stating that they are out of scope or not applicable):

#### Story / Description
1. Where applicable (for more complicated tickets), please include a brief rationale for this solution to the problem.

#### Dependencies
1. Link any other related tickets. This is particularly important for blockers.

#### Accessibility
1. Keyboard operability
1. Screen-reader usability

#### Style Guide
1. If a specific component from the styleguide is supposed to be used, please name that component.

#### Mockups and Specs
1. If the mockups and specs are inconsistent with each other, or are out of date, please note this explicitly.
1. Specify all colors used (preferably in terms of semantic variables like `$tag-backgrond-color`)
    1. Pixel or percentage measurements for layout

#### Icons
1. Ensure that all necessary SVGs are linked from the ticket and render correctly in the GitHub browser. Do not add new icons that are Font (not so) Awesome.

#### Error Handling
1. What happens for invalid / unexpected user input?
1. What happens for server failure?
1. If necessary, consult with engineer about which errors may occur

#### Data persisting to the backend
1. What actions cause data to be saved?
1. Is there a "save successful" indicator?

#### Latency
1. Is there a loading indicator?

### Ready For PR
1. The PR improves the app in some way
1. Tests are passing on Travis
1. New tests are added for new functionality
1. There are no new warnings in the test output
1. There are no new console errors in the browser
1. PR only addresses one ticket, unless:
    * Addressing a separate ticket only requires a small amount (~10 lines) of code.
    * Two tickets are fixed by the same diff / the two tickets really should have been one ticket
    * Some other very good reason
1. Everything (comments, variable names, etc) is spelled correctly using American English
1. Best practices
    1. Redux
        1. No computed state is being stored in Redux
        1. If you're adding new state to Redux, add it to the initial state, even if the initial value is falsey:
            ```js
              initialState = {
                // ...
                myNewValue: null
              }
            ```
        1. All actions are used
        1. All actions have a reducer part that updates the state
    1. Lodash is being used effectively
    1. All variables are scoped as tightly as possible
    1. Class methods all use `this`; if `this` is not needed, it shouldn't be a class method
    1. All CSS colors are variables, not magic values
1. Feedback from previous PRs about style and best practices is applied in this PR as well

### Ready To Merge
1. Use the React perf tools to see if there are extra new renders
1. Use the Network tools to see if there are superfluous requests
1. Use the Redux tools to see if there are superfluous actions
1. Everything in [this doc](https://1drv.ms/w/s!Av1mb2ibWxcMlKxcfn2PyVPt_ZGWPQ)

## Hypothesis / Rationale
We move tickets through a series of steps. When a ticket is moved to the next step too soon, it causes churn. If we look at these checklists before moving tickets to the next step, we may be able to reduce churn.