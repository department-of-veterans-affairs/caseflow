import React, { Fragment } from 'react';
import Alert from '../../components/Alert';
import BareList from '../../components/BareList';
import _ from 'lodash';

const missingFieldsMessage = (fields) => <p>
  Please fill in the following field(s) in the Veteran's profile in VBMS or the corporate database,
  then retry establishing the EP in Caseflow: {fields}.
</p>;

const addressTips = [
  () => <Fragment>Do: move the last word(s) of the street address down to an another street address field</Fragment>,
  () => <Fragment>Do: abbreviate to St. Ave. Rd. Blvd. Dr. Ter. Pl. Ct.</Fragment>,
  () => <Fragment>Don't: edit street names or numbers</Fragment>
];

const addressTooLongMessage = <Fragment>
  <p>
    This Veteran's address is too long. Please edit it in VBMS or SHARE so each address field is no longer than
    20 characters (including spaces) then try again.
  </p>
  <p>Tips:</p>
  <BareList items={addressTips} ListElementComponent="ul" />
</Fragment>;

export const invalidVeteranInstructions = (searchErrorData) => {
  if (searchErrorData) {
    return <Fragment>
      { (_.get(searchErrorData.veteranMissingFields, 'length', 0) > 0) &&
        missingFieldsMessage(searchErrorData.veteranMissingFields) }
      { searchErrorData.veteranAddressTooLong && addressTooLongMessage }
    </Fragment>;
  }
};

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
            If it's still not working after that, please contact the Caseflow team
            via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
            via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
          </Fragment>
        )
      },
      default: {
        title: 'Something went wrong',
        body: (
          <Fragment>
            <div>Error code {this.props.errorUUID}</div>
            <div>
              Please try again. If the problem persists, please contact the Caseflow team
              via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
              via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
            </div>
          </Fragment>
        )
      },
      veteran_not_valid: {
        title: "The Veteran's profile has missing or invalid information required to create an EP.",
        body: invalidVeteranInstructions(this.props.errorData)
      }
    }[this.props.errorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}
