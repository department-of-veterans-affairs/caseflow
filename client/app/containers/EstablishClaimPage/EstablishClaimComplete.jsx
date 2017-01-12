import React, { PropTypes } from 'react';
import ApiUtil from '../../util/ApiUtil';

import Button from '../../components/Button';

export default class EstablishClaimComplete extends React.Component {

  render() {
    let {
      availableTasks,
      buttonText,
      checklist,
      content,
      firstHeader,
      secondHeader
    } = this.props;

    return <div
        id="certifications-generate"
        className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
      <h1 className="cf-success cf-msg-screen-heading">{firstHeader}</h1>
      <h2 className="cf-msg-screen-deck">{secondHeader}</h2>

      <ul className="cf-list-checklist">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
      { content &&
        <ul className="cf-list-checklist">
            {content}
        </ul>
      }
      <div className="cf-centered-buttons">
        <a href="/dispatch/establish-claim">View History</a>
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
