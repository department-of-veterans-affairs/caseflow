import React, { PropTypes } from 'react';
import ApiUtil from '../../util/ApiUtil';
import ProgressBar from '../../components/ProgressBar';

import Button from '../../components/Button';

export default class EstablishClaimComplete extends React.Component {

  getProgressBarSections() {
    return [
      { 'title' : '1. Review Decision', 'activated' : true },
      { 'title' : '2. Route Claim', 'activated' : true },
      { 'title' : '3. Confirmation', 'activated' : true }
    ];
  }

  render() {
    let {
      availableTasks,
      buttonText,
      checklist,
      content,
      firstHeader,
      secondHeader
    } = this.props;

    return <div>
      <ProgressBar
          sections={this.getProgressBarSections()}
      />
      <div
        id="certifications-generate"
        className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
      <h1 className="cf-success cf-msg-screen-heading">{firstHeader}</h1>
      <h2 className="cf-msg-screen-deck">{secondHeader}</h2>

      <ul className="cf-list-checklist">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
      { content &&
        <ul className="cf-msg-screen-deck">
            {content}
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
  firstHeader: PropTypes.string,
  secondHeader: PropTypes.string
};
