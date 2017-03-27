import React, { PropTypes } from 'react';
import EstablishClaimProgressBar from './EstablishClaimProgressBar';

import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';

const PARSE_INT_RADIX = 10;

export default class EstablishClaimComplete extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isLoading: false
    };
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

    quotaReachedMessage = <h2 className="cf-msg-screen-deck">
      Way to go! 💻💪🇺🇸<br/>
      You have completed all of the total cases assigned to you today.
    </h2>;

    totalCases = totalCasesToComplete + totalCasesCompleted;
    employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

    casesAssigned = employeeCountInt > 0 ?
      Math.ceil(totalCases / employeeCountInt) : 0;
    hasQuotaReached = (totalCasesCompleted >= casesAssigned) && (casesAssigned > 0);

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
          onClick={this.establishNextClaim}
          classNames={["usa-button-primary", "cf-push-right"]}
          loading={this.state.isLoading}
        />
      </div>;
    };

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

  establishNextClaim = () => {
    this.setState({
      isLoading: true
    });

    ApiUtil.patch(`/dispatch/establish-claim/assign`).
    then((response) => {
      window.location = `/dispatch/establish-claim/${response.body.next_task_id}`;
    }, () => {
      this.props.handleAlert(
        'error',
        'Error',
        'There was an error establishing the next claim. Please try again later'
      );

      this.setState({
        isLoading: false
      });
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
