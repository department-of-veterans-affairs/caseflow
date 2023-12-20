# Transitioning alerts

## Context

A few months back, Lomax introduced a new way of displaying alerts to users. In this [PR](https://github.com/department-of-veterans-affairs/caseflow/pull/12772), Lomax created a generic new component `UserAlerts` which displays alerts stored in a global redux state called `alerts`. There are some redux state actions like `onReceiveAlerts(alerts)` which takes an array of alerts and sets that array to the global state, which triggers the re-rendering of the `UserAlerts` component.

In `DailyDocket` and `Details` page, the alert objects are returned from the backend (`HearingsController`) on any updates to hearings which includes virtual hearing.

A sample alert object:

```ruby
{
  type: :info,
  title: "",
  message: ""
}
```

The alerts list returned can include a *generic* hearing update alert and/or a *specific* virtual hearing update alert. This list of alerts is then put into the global redux state `alerts` using `onReceiveAlerts` and correspondingly displayed by `UserAlerts`. The reason this approach was taken was because the backend knows which changes are made to a virtual hearing and can create the necessary alerts to be displayed to the user. For example, if a user changes the hearing time, the alert displayed is the following: 

```
You have successfully updated the time of x's virtual hearing.
Email notifications were sent to the Veteran and POA/Representative.
```

These virtual hearing alerts are considered `info` since any changes made to virtual hearings triggers an async job (`CreateConferenceJob`) to begin.



Now, we want to add a `success` alert to inform the user that the changes they requested have been made i.e the async job is completed. We still want to keep the `info` alert, but when the job finishes, replace it with the `success` alert. 

A few things to note:

1. We poll for the job status periodically (with exponential backoff) until it finishes.
2. In order to simplify the backend, we generate the success alert when the initial request to change is made. The success alert is returned with all the other alerts (including the info alert that should be shown before it).

## Design problem

How do we transition from `info` to `success`?

Since the `UserAlerts` component only renders the alerts in the global redux state `alerts`, the target of our change has to be the redux state.

Steps needed to complete transition:

1. Remove `info` alert from global redux state `alerts`
2. Add `success` alert to the global redux state `alerts`

## Solutions

### Solution 1

Given a flat list of alerts returned by the server (hearing and virtual hearing alerts mixed) we need to:

1. Filter the list of alerts for the generic hearing alerts and the `info` virtual hearing alert and pass them to `onReceiveAlerts` to be displayed immediately.
2. Save the `success` alert to state and pass to `onReceiveAlerts` upon job completion.
3. Remove the `info` alert upon job completion.

That is what my first [solution](https://github.com/department-of-veterans-affairs/caseflow/pull/13702) did.

There was very alerts specific filtering logic inside the components, which did not look very good.

To remove this specific filtering from the frontend, it simply means we need to separate the alerts on the backend. We can separate into hearing alerts and virtual hearing alerts, show-now and show-later, or simple and multi-stage. I chose hearing and virtual hearing.

### Solution 2

A modified server response can be:

```javascript
{
 "hearing": [],
 "virtualHearing": [
   {"type": "info"},
   {"type": "success"}
 ]
}
```

I can immediately pass the hearing alerts to `onReceiveAlerts`. I can also call `onReceiveAlerts` with the first virtual hearing alert (`info` at index 0). The virtual hearing alerts are saved to state. Upon job completion the `info` alert is removed, the `success` added.

Some alternative server responses:

*Explicit object instead of array indices*

```javascript
{
 "hearing": [],
 "virtualHearing": {
   "now": [{"type": "info"}],
   "later": [{"type": "success"}]
 }
}
```

*Nested*

```javascript
{
 "hearing": [],
 "virtualHearing": [
    {
     "type": "info",
      "title": "",
      "message": "",
      "next": [
        {
           "type": "success"
   	}
      ]
    }
  ]
}
```

------

The question now is not about server response format but where to put the transition logic. 

We can put it into the component that receives the server response. It would store the virtual hearing alerts in state and call a redux function to remove the `info` alert and display the `success` alert when the job completed.

Alternatively, we can store the virtual hearing alerts in a new global redux state, say `transitioningAlerts` that stores each group of multi-stage alerts (`info` and `success`). We can then write a redux action `transitionAlert(alert)`, which takes the alert to transition to or from. The action finds the alert in one of the alert groups in the redux state `transitioningAlerts` and handles the transition logic from there (remove old alert from `alerts` redux state (can be renamed to *activeAlerts* for clarity), display new alert using `receiveAlerts`). This approach is better because it does away with specific alert logic inside the components and generalizes from "virtual hearing alerts" to just multi-stage alerts. Obviously, the alert in question still needs to be stored in component `state` to pass it to *transitionAlert*.

But we could also store the the transitioning alert groups with their group names like so and then we bypass the need to store the alert in component state at all.

```javascript
{
 "virtualHearing": [
    {
      "type": "info",
      "title": "",
      "message": "",
      "next": [{"type": "success"}]
    }
  ],
  "someOtherGroup": [
    
  ]
}
```

So instead we would call the redux action `transitionAlert("virtualHearing")` and it would handle the transition logic. *This example uses the nested alert response format, but it can also be an array or object as in the previous examples*. 