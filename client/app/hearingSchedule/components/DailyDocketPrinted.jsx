import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Table from '../../components/Table';
import { getDisplayTime } from './DailyDocketRowDisplayText';

// TODO: Shared with HearingWorksheetContainer.jsx
const PRINT_WINDOW_TIMEOUT_IN_MS = 150;

export class DailyDocketPrinted extends React.Component {
  componentDidMount() {
    setTimeout(() => window.print(), PRINT_WINDOW_TIMEOUT_IN_MS);
  }

  isUserJudge = () => this.props.user.userRoleHearingPrep;

  getTableColumns = () => [
    {
      header: 'Time',
      valueFunction: (hearing) => {
        const localTimezone = hearing.regionalOfficeTimezone || 'America/New_York';

        return getDisplayTime(hearing.scheduledTimeString, localTimezone);
      }
    },
    {
      header: 'Docket Number',
      valueName: 'docketNumber'
    },
    {
      header: '',
      valueFunction: (hearing) => {
        const veteranName = `${hearing.veteranFirstName} ${hearing.veteranLastName}`;
        const representativeName = hearing.representativeName || hearing.representative;

        return (
          <div>
            <strong>Veteran:</strong> {veteranName}<br />
            <strong>Representative:</strong> {representativeName}<br />
            <strong>Location:</strong> {hearing.readableLocation}<br />
            <strong>Disposition:</strong> {hearing.disposition}<br />
            {this.isUserJudge() &&
              <span><strong>AOD:</strong> {hearing.aod}</span>
            }
            {hearing.notes &&
              <p><strong>Notes:</strong> {hearing.notes}</p>
            }
          </div>
        );
      }
    }
  ];

  render() {
    const { docket, hearings } = this.props;

    return (
      <AppSegment>
        <h1>Daily Docket ({moment(docket.scheduledFor).format('ddd M/DD/YYYY')})</h1>

        <div className="cf-app-segment">
          <div className="cf-push-left">
            <strong>VLJ:</strong> {docket.judgeFirstName} {docket.judgeLastName} <br />
            <strong>Coordinator:</strong> {docket.bvaPoc} <br />
            <strong>Hearing type:</strong> {docket.readableRequestType} <br />
            <strong>Regional office:</strong> {docket.regionalOffice}<br />
            <strong>Room number:</strong> {docket.room}
          </div>
        </div>

        <Table
          columns={this.getTableColumns()}
          rowObjects={Object.values(hearings)}
          slowReRendersAreOk />

        <h2>Previous Hearings</h2>

        <Table
          columns={this.getTableColumns()}
          rowObjects={[]}
          slowReRendersAreOk />
      </AppSegment>
    );
  }
}

DailyDocketPrinted.propTypes = {
  user: PropTypes.object.isRequired,
  docket: PropTypes.object,
  hearings: PropTypes.object
};

export default DailyDocketPrinted;
