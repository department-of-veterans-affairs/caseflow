import React from 'react';
import Alert from '../../components/Alert';

export default class CompleteIntakeErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      duplicate_ep: {
        title: 'An EP for this claim already exists in VBMS',
        body: `An EP ${this.props.completeIntakeErrorData} for this Veteran's claim was created` +
              ' outside Caseflow. Please tell your manager as soon as possible so they can resolve the issue.'
      },
      long_address: {
        title: 'The address is too long',
        body: `Please shorten the Veteran's Address Line 1 in VBMS to 20
          characters or less (including spaces), then try again.`
      },
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    }[this.props.completeIntakeErrorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}
