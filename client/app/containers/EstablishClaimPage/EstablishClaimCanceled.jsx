import React from 'react';
import PropTypes from 'prop-types';

import EstablishClaimToolbar from './EstablishClaimToolbar';
import StatusMessage from '../../components/StatusMessage';

const PARSE_INT_RADIX = 10;

const MESSAGE_TEXT = 'You can now establish the next claim or go back' +
' to your Work History.';

export default class EstablishClaimCanceled extends React.Component {

  render() {

    let {
      availableTasks,
      buttonText,
      employeeCount,
      secondHeader,
      totalCasesCompleted,
      totalCasesToComplete
    } = this.props;

    let casesAssigned, employeeCountInt, totalCases;

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;

    return <div>
      <StatusMessage
        title="Claim Processing Discontinued"
        leadMessageList={[secondHeader]}
        messageText={MESSAGE_TEXT}
        type="alert" />
      <EstablishClaimToolbar
        availableTasks={availableTasks}
        buttonText={buttonText}
        casesAssigned={casesAssigned}
        totalCasesCompleted={totalCasesCompleted}
      />
    </div>;
  }

}

EstablishClaimCanceled.propTypes = {
  availableTasks: PropTypes.bool,
  buttonText: PropTypes.string,
  employeeCount: PropTypes.string,
  secondHeader: PropTypes.string,
  totalCasesCompleted: PropTypes.number,
  totalCasesToComplete: PropTypes.number
};
