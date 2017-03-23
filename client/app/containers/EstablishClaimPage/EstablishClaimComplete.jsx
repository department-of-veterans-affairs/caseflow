import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';

import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';

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

    const noMoreCasesMessage = <div>There are no more cases to work today.
    <a href="/dispatch/establish-claim"> Return to homepage</a> to view your work history.
    </div>;

    quotaReachedMessage = `Way to go! You have completed all of the total cases
      assigned to you today.`;

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = totalCasesCompleted >= casesAssigned;

    let NoMoreClaimsButton = () => {
      return <div>
        <span className="cf-button-associated-text-right">
          There are no more claims in your queue
        </span>

        <Button
          name={buttonText}
          classNames={["cf-push-right"]}
          disabled={true}
        />
      </div>;
    };

    let NextClaimButton = () => {
      return <div>
        <span className="cf-button-associated-text-right">
          { casesAssigned } cases assigned, { totalCasesCompleted } completed
        </span>

        <Button
          name={buttonText}
          onClick={this.onClick}
          classNames={["usa-button-primary", "cf-push-right"]}
        />
      </div>;
    };

    return <div>
      <EstablishClaimProgressBar
        isConfirmation={true}
        isReviewDecision={true}
        isRouteClaim={true}
      />

      <div
        id="certifications-generate"
        className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">

      <h1 className="cf-success cf-msg-screen-heading">{firstHeader}</h1>
      <h2 className="cf-msg-screen-deck">{secondHeader}</h2>

      <ul className="cf-list-checklist cf-left-padding">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
    </div>

    <div className="cf-app-segment">
      <div className="cf-push-left">
        <a href="/dispatch/establish-claim">View Work History</a>
      </div>

      <div className="cf-push-right">
        { availableTasks && <NextClaimButton /> }
        { !availableTasks && <NoMoreClaimsButton /> }
      </div>
    </div>
    </div>;
  }

  onClick = () => {
    ApiUtil.patch(`/dispatch/establish-claim/assign`).then((response) => {
      window.location = `/dispatch/establish-claim/${response.body.next_task_id}`;
    });
  };

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
