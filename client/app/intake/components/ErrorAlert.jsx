import React, { Fragment } from 'react';
import Alert from '../../components/Alert';

export default class ErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      duplicate_ep: {
        title: 'An EP for this claim already exists in VBMS',
        body: `An EP ${this.props.errorData} for this Veteran's claim was created` +
              ' outside Caseflow. Please tell your manager as soon as possible so they can resolve the issue.'
      },
      request_issues_data_empty: {
        title: 'No issues were selected',
        body: 'Please select at least one issue and try again.'
      },
      no_changes: {
        title: 'No changes were selected',
        body: 'Please select at least one change and try again.'
      },
      previous_update_not_done_processing: {
        title: 'Previous update not yet done processing',
        body: (
          <Fragment>
            A previously submitted update has not yet finished processing. Please wait a few minutes and try again.
            <br /><br />
            If it's still not working after that, please contact customer support.
          </Fragment>
        )
      },
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    }[this.props.errorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}
