import React from 'react';
import Alert from '../../components/Alert';

export default class ReviewIntakeErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      default: {
        title: 'Something went wrong',
        body: 'Please try again. If the problem persists, please contact Caseflow support.'
      }
    }[this.props.reviewIntakeErrorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}
