import React, { PropTypes } from 'react';

import ApiUtil from '../../util/ApiUtil';
import Button from '../../components/Button';

const PARSE_INT_RADIX = 10;

export default class EstablishClaimComplete extends React.Component {

  render() {

    /*
      NOTE: Do not provide 'content' as a prop if stats need to be shown
      as feedback message.
    */
    let {
      availableTasks,
      buttonText,
      checklist,
      content,
      firstHeader,
      secondHeader,
      totalCasesCompleted,
      totalCasesToComplete,
      employeeCount
    } = this.props;

    let casesAssigned, employeeCountInt,
      noCasesLeft, todayfeedbackText, totalCases;

    const noMoreCasesMessage = `There are no more cases to work today.
      <a href="/dispatch/establish-claim">Return to homepage</a> to view your \
      work history.`;


    // there are certain containers using this component without these
    // stats being specified.
    if (totalCasesCompleted && totalCasesToComplete && employeeCount) {
      noCasesLeft = totalCasesToComplete === totalCasesCompleted;
      totalCases = totalCasesToComplete + totalCasesCompleted;
      employeeCountInt = parseInt(employeeCount, PARSE_INT_RADIX);

      casesAssigned = employeeCountInt > 0 ?
        Math.ceil(totalCases / employeeCountInt) : 0;

      todayfeedbackText = noCasesLeft ? '' : ' today';
    }

    return <div>
      <div
        id="certifications-generate"
        className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
      <h1 className="cf-success cf-msg-screen-heading">{firstHeader}</h1>
      <h2 className="cf-msg-screen-deck">{secondHeader}</h2>

      <ul className="cf-list-checklist">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
      { <ul className="cf-list-checklist eastablish-claim-feedback">
        <div>
         <div>{content ?
          content :
          `Way to go! You have completed ${totalCasesCompleted} out of the
          ${casesAssigned} cases assigned to you${todayfeedbackText}.`}</div>
          {noCasesLeft ?
            <div dangerouslySetInnerHTML={{ __html: noMoreCasesMessage }}></div> :
            `You can now establish the next claim or go back to your work history.`
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
        <Button
            name={buttonText}
            classNames={["usa-button-disabled", "cf-push-right"]}
            disabled={true}
        />
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
  content: PropTypes.string,
  employeeCount: PropTypes.string,
  firstHeader: PropTypes.string,
  secondHeader: PropTypes.string,
  totalCasesAssigned: PropTypes.number,
  totalCasesCompleted: PropTypes.number
};
