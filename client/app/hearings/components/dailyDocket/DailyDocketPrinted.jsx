import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment';

import { getDate, getDisplayTime } from '../../../util/DateUtil';
import { isPreviouslyScheduledHearing, sortHearings, dispositionLabel } from '../../utils';
import { openPrintDialogue } from '../../../util/PrintUtil';
import AOD_CODE_TO_LABEL_MAP from '../../../../constants/AOD_CODE_TO_LABEL_MAP';
import Table from '../../../components/Table';

export class DailyDocketPrinted extends React.Component {
  componentDidMount() {
    window.onafterprint = () => window.close();

    document.title += ` ${getDate(this.props.docket.scheduledFor)}`;

    if (!this.props.disablePrompt) {
      openPrintDialogue();
    }
  }

  isUserJudge = () => this.props.user.userHasHearingPrepRole;

  getTableColumns = () => [
    {
      header: 'Time',
      valueFunction: (hearing) => {
        const localTimezone = hearing.regionalOfficeTimezone || 'America/New_York';

        return getDisplayTime(hearing.scheduledTimeString, localTimezone);
      }
    },
    {
      header: '',
      valueFunction: (hearing) => {
        const disposition = dispositionLabel(hearing?.disposition);

        return (
          <div>
            <strong>Number:</strong> {hearing.docketNumber}<br />
            <strong>Disposition:</strong> {disposition}<br />
            {this.isUserJudge() &&
              <span>
                <strong>AOD:</strong> {hearing.aod ? AOD_CODE_TO_LABEL_MAP[hearing.aod] : 'None'}
              </span>
            }
          </div>
        );
      }
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
            <span>
              <strong>Type:</strong> {hearing.isVirtual ? 'Virtual' : hearing.readableRequestType}<br />
            </span>
            {hearing.notes &&
              <span><strong>Notes:</strong> {hearing.notes}</span>
            }
          </div>
        );
      }
    }
  ];

  render() {
    const { docket, hearings } = this.props;
    const allHearings = sortHearings(hearings);
    const currentHearings = _.filter(allHearings, _.negate(isPreviouslyScheduledHearing));
    const previousHearings = _.filter(allHearings, isPreviouslyScheduledHearing);

    return (
      <AppSegment extraClassNames={['cf-daily-docket-printed']}>
        <div className="cf-app-segment">
          <div className="cf-push-left">
            <h2>Daily Docket ({moment(docket.scheduledFor).format('ddd M/DD/YYYY')})</h2>
            {docket.notes &&
              <div>
                <strong>Notes:</strong><br />
                {docket.notes}
              </div>
            }
          </div>

          <div className="cf-push-right">
            <strong>VLJ:</strong> {docket.judgeFirstName} {docket.judgeLastName} <br />
            <strong>Coordinator:</strong> {docket.bvaPoc} <br />
            <strong>Hearing type:</strong> {docket.readableRequestType} <br />
            <strong>Regional office:</strong> {docket.regionalOffice}<br />
            <strong>Room number:</strong> {docket.room}
          </div>
        </div>

        <Table
          columns={this.getTableColumns()}
          rowObjects={currentHearings}
          slowReRendersAreOk
        />

        {_.size(previousHearings) > 0 &&
          <div>
            <h2>Previous Hearings</h2>

            <Table
              columns={this.getTableColumns()}
              rowObjects={previousHearings}
              slowReRendersAreOk
            />
          </div>
        }
      </AppSegment>
    );
  }
}

DailyDocketPrinted.propTypes = {
  user: PropTypes.object.isRequired,
  docket: PropTypes.object,
  hearings: PropTypes.object,

  // Whether or not to display the print screen prompt.
  disablePrompt: PropTypes.bool
};

DailyDocketPrinted.defaultProps = {
  disablePrompt: false
};

export default DailyDocketPrinted;
