import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';
import EstablishClaimToolbar from './EstablishClaimToolbar';

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

    quotaReachedMessage = <h2 className="cf-msg-screen-deck">
      Way to go! 💻💪🇺🇸<br/>
      You have completed all of the total cases assigned to you today.
    </h2>;

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

    console.log(availableTasks);
    console.log(buttonText);
    console.log(employeeCount);
    console.log(secondHeader);
    console.log(totalCasesCompleted);
    console.log(totalCasesToComplete);

    return <div>
      <EstablishClaimProgressBar
        isConfirmation={true}
      />

      <div
        id="certifications-generate"
        className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">

      <h1 className="cf-success cf-msg-screen-heading">{firstHeader}</h1>
      <h2 className="cf-msg-screen-deck">
        {secondHeader}
      </h2>

      {hasQuotaReached && quotaReachedMessage}

      <ul className="cf-list-checklist cf-left-padding">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
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
