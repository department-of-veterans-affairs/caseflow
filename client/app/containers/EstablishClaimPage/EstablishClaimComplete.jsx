import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import EstablishClaimToolbar from './EstablishClaimToolbar';
import SuccessMessage from '../../components/SuccessMessage';

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
      hasQuotaReached, quotaReachedMessage, successMessages, totalCases;

    quotaReachedMessage = () => {
      if (hasQuotaReached) {
        return <span>
          Way to go! 💻💪🇺🇸<br/>
          You have completed all of the total cases assigned to you today.
        </span>;
      }
    };

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

    successMessages = [secondHeader, quotaReachedMessage()];

    return <div>
      <EstablishClaimProgressBar
        isConfirmation={true}
      />

      <SuccessMessage
        title={firstHeader}
        leadMessageList={successMessages}
        checklist={checklist}
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
