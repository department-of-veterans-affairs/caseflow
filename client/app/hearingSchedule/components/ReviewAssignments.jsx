import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY.json';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../../components/Alert';
import Button from '../../components/Button';
import { SPREADSHEET_TYPES } from '../constants';

export default class ReviewAssignments extends React.Component {

  getAlertTitle = () => {
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_ROCO;
    }
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_TITLE_JUDGE;
    }
  };

  getAlertMessage = () => {
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.RoSchedulePeriod.value) {
      return <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_ROCO}</p>;
    }
    if (this.props.schedulePeriod.type === SPREADSHEET_TYPES.JudgeSchedulePeriod.value) {
      return <p>{COPY.HEARING_SCHEDULE_REVIEW_ASSIGNMENTS_ALERT_MESSAGE_JUDGE}</p>;
    }
  };

  getAlertButtons = () => {
    return <div>
      <Link
        name="go-back"
        button="secondary"
        to="/schedule/build/upload">
        Go back
      </Link>
      <Button>
        Confirm Assignments
      </Button>
    </div>;
  };

  render() {
    return <AppSegment filledBackground>
      <Alert
        type="info"
        title={this.getAlertTitle()}
        message={<div>{this.getAlertMessage()}{this.getAlertButtons()}</div>}
      />
    </AppSegment>;
  }
}

ReviewAssignments.propTypes = {
  schedulePeriod: PropTypes.object
};
