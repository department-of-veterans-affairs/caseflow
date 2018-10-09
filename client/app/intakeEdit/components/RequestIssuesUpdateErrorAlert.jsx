import React, { Fragment } from 'react';
import Alert from '../../components/Alert';

export default class RequestIssuesUpdateErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
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
    }[this.props.responseErrorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}
