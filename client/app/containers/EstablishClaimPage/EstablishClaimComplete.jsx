import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import EstablishClaimToolbar from './EstablishClaimToolbar';
import StatusMessage from '../../components/StatusMessage';

const PARSE_INT_RADIX = 10;

export default class EstablishClaimComplete extends React.Component {

  render() {

    let {
      availableTasks,
      buttonText,
      checklist,
      firstHeader,
      secondHeader,
      totalCasesCompleted,
      totalCasesToComplete,
      employeeCount
    } = this.props;

    let casesAssigned, employeeCountInt,
      hasQuotaReached, quotaReachedMessage, totalCases;

    quotaReachedMessage = () => {
      if (hasQuotaReached) {
        return <span>
            <h2>Way to go!</h2> 💪💻🇺🇸<br/>
            <h2 className ="cf-msg-screen-deck cf-success-emoji-text">
             You have completed all of the total cases assigned to you today.
            </h2>
          </span>;
      }
    };


    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

    return <div>
      <EstablishClaimProgressBar
        isConfirmation={true}
      />

    <StatusMessage
        title={firstHeader}
        leadMessageList={[secondHeader]}
        checklist={checklist}
        messageText={hasQuotaReached && quotaReachedMessage()}
        type="success"
        />

    <EstablishClaimToolbar
      availableTasks={availableTasks}
      buttonText={buttonText}
      casesAssigned={casesAssigned}
      totalCasesCompleted={totalCasesCompleted}
    />
    </div>;
  }

}

EstablishClaimComplete.propTypes = {
  availableTasks: PropTypes.bool,
  buttonText: PropTypes.string,
  checklist: PropTypes.array,
  employeeCount: PropTypes.string,
  firstHeader: PropTypes.string,
  secondHeader: PropTypes.string,
  totalCasesAssigned: PropTypes.number,
  totalCasesCompleted: PropTypes.number
};
