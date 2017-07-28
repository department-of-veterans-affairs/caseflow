# Contributing to Styleguide

This is a very basic guide on how to contribute something to the style guide for developers, designers, and anyone else interested in contributing.

Link in demo: http://dsva-appeals-certification-demo-1715715888.us-gov-west-1.elb.amazonaws.com/styleguide

## How can I request that something is put in the style guide?
In an upcoming story, make it an AC item that the UI component you'd like to add should
be placed in the style guide.

IE:
_progress bar/indicator_
* [App ticket](https://github.com/department-of-veterans-affairs/caseflow/issues/617)
* [Styleguide ticket](https://github.com/department-of-veterans-affairs/caseflow/issues/1009)

_accordion_
* [App ticket](https://github.com/department-of-veterans-affairs/caseflow/issues/2161)
* [Styleguide ticket](https://github.com/department-of-veterans-affairs/caseflow/issues/1482)

Ideally, the same developer that picks up that story should also be the one to add it to the styleguide (see below information on that).

If we currently have that UI component in an application but no information on the style guide about that component, create a ticket and label it with `styleguide` for a developer to pick up.

For new UI components that will need to be added to the style guide (that aren't already used in our applications), it must first already be implemented in the app or about to be implemented in an upcoming story.

## (For developers) What can I add to style guide?
Similar to our current products, we put tickets that we'd like to work on in "Current Sprint"
for the current sprint. However, tickets that are also in "Ready for Dev" are good to work
on too if there is nothing in the "Current Sprint" section. Here is the unofficial hierarchy of what to contribute for style guide (starting with most important to least important):

* Any story that implements a new UI component
* Any story that lists "add this [UI component] to style guide" (for new or existing UI components)
* "Current Sprint" tickets
* "Ready for Dev" tickets

## (For developers) How to add a component to the styleguide?
The AC of your ticket will specify how the component should look, and for each ticket you will need to do the following:

* Add the component description/sample component implementation in a Styleguide container (see `client/app/containers/Styleguide` for examples)
* Create or modify the base UI component in `client/app/components`
* (if applicable) Apply these changes across the whole app
* Add any necessary styles to [caseflow-commons](https://github.com/department-of-veterans-affairs/caseflow-commons/) repo and/or make a note to add the styles to the repo in your `.scss file`
