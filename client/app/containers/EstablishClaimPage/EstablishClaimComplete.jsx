import React, { PropTypes } from 'react';
import ProgressBar from '../../components/ProgressBar';

import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';

const PARSE_INT_RADIX = 10;

export default class EstablishClaimComplete extends React.Component {

  getProgressBarSections() {
    return [
      {
        'activated': true ,
        'title': '1. Review Decision'
      },
      {
        'activated': true,
        'title': '2. Route Claim'
      },
      {
        'activated': true,
        'title': '3. Confirmation'
      }
    ];
  }

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

    return <div>
      <ProgressBar
          sections={[
            {
              'activated': true ,
              'title': '1. Review Decision'
            },
            {
              'activated': true,
              'title': '2. Route Claim'
            },
            {
              'activated': true,
              'title': '3. Confirmation'
            }
          ]}
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
      { <ul className="cf-list-checklist establish-claim-feedback">
        <div>
         <div>{hasQuotaReached ?
          quotaReachedMessage :
          `Way to go! You have completed ${totalCasesCompleted} out of the
          ${casesAssigned} cases assigned to you today.`}</div>
          {availableTasks ?
            `You can now establish the next claim or go back to your work history.` :
            noMoreCasesMessage
          }
         </div>
        </ul>
      }
    </div>
    <div className="cf-app-segment">
      <div className="cf-push-left">
        <a href="/dispatch/establish-claim">View Work History</a>
      </div>
      <div className="cf-push-right">
        { availableTasks &&
        <Button
          name={buttonText}
          onClick={this.onClick}
          classNames={["usa-button-primary", "cf-push-right"]}
          disabled={!availableTasks}
        />
        }
        { !availableTasks &&
        <div>
          <span className="cf-button-associated-text-right">
            { "There are no more claims in your queue" }
          </span>
          <Button
            name={buttonText}
            classNames={["usa-button-disabled", "cf-push-right"]}
            disabled={true}
        />
        </div>
        }
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
