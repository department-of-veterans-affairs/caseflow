import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import EstablishClaimToolbar from './EstablishClaimToolbar';

const PARSE_INT_RADIX = 10;

export default class EstablishClaimCanceled extends React.Component {

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

    quotaReachedMessage = <h2 className="cf-msg-screen-deck">
        Way to go! 💻💪🇺🇸<br/>
        You have completed all of the total cases assigned to you today.
    </h2>;

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
        Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

    return <div>
        <div>
        <EstablishClaimProgressBar
            isConfirmation={true}
        />

        <div id="certifications-generate" className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
            <h1 className="cf-red-text cf-msg-screen-heading">Claim Processing Discontinued</h1>
            <h2 className="cf-msg-screen-deck">{secondHeading}</h2>
            <p className="cf-msg-screen-text">
                You can now establish the next claim or go back to your Work History.</p>
        </div>
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
  checklist: PropTypes.array,
  employeeCount: PropTypes.string,
  firstHeader: PropTypes.string,
  secondHeader: PropTypes.string,
  totalCasesAssigned: PropTypes.number,
  totalCasesCompleted: PropTypes.number
};
