import React from 'react';
import Alert from '../../components/Alert';

export default class ErrorAlert extends React.PureComponent {
  render() {
    return <Alert title="Something went wrong" type="error" lowerMargin>
      Please try again. If the problem persists, please contact Caseflow support.
    </Alert>;
  }
}
