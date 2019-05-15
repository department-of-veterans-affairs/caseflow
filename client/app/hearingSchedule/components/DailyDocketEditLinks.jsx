import React from 'react';
import { CSVLink } from 'react-csv';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../components/Button';
import { crossSymbolHtml, pencilSymbol, lockIcon } from '../../components/RenderFunctions';

const EditHearingDayLink = ({ openModal }) => (
  <Button {...css({ marginLeft: '30px' })} linkStyling onClick={openModal} >
    <span {...css({ position: 'absolute' })}>{pencilSymbol()}</span>
    <span {...css({
      marginRight: '5px',
      marginLeft: '20px'
    })}>
        Edit Hearing Day
    </span>
  </Button>
);

const LockHearingLink = ({ dailyDocket, onDisplayLockModal }) => (
  <Button linkStyling onClick={onDisplayLockModal}>
    <span {...css({ position: 'absolute',
      '& > svg > g > g': { fill: '#0071bc' } })}>
      {lockIcon()}
    </span>
    <span {...css({ marginRight: '5px',
      marginLeft: '16px' })}>
      {dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day'}
    </span>
  </Button>
);

const RemoveHearingDayLink = ({ onClickRemoveHearingDay }) => (
  <Button
    linkStyling
    onClick={onClickRemoveHearingDay} >
    {crossSymbolHtml()}<span{...css({ marginLeft: '3px' })}>Remove Hearing Day</span>
  </Button>
);

export default class DailyDocketEditLinks extends React.Component {

  isUserJudge = () => this.props.user.userRoleHearingPrep;

  exportDailyDocket() {
    const { hearings } = this.props;

    return hearings.map((hearing) => {
      const row = {
        date: hearing.scheduledFor,
        time: hearing.scheduledFor,
        vlj: "",
        hearingCoordinator: "",
        regionalOffice: hearing.regionalOfficeName,
        hearingLocation: hearing.readableLocation,
        hearingType: hearing.readableRequestType,
        hearingRoom: hearing.room,
        docketNumber: hearing.docketNumber,
        veteranName: `${hearing.veteranFirstName} ${hearing.veteranLastName}`,
        representativeName: hearing.representativeName || hearing.representative,
        disposition: hearing.disposition,
        notes: hearing.notes || ''
      };

      if (this.isUserJudge()) {
        row["aod"] = hearing.aod;
      }

      return row;
    });
  }

  getExportDailyDocketHeaders() {
    const headers = [
      { label: "Date", key: "date" },
      { label: "Time", key: "time" },
      { label: "VLJ", key: "vlj" },
      { label: "Hearing Coordinator", key: "hearingCoordinator" },
      { label: "Regional Office", key: "regionalOffice" },
      { label: "Hearing Location", key: "hearingLocation" },
      { label: "Hearing Type", key: "hearingType" },
      { label: "Hearing Room", key: "hearingRoom" },
      { label: "Docket Number", key: "docketNumber" },
      { label: "Veteran Name", key: "veteranName" },
      { label: "Representative Name", key: "representativeName" },
      { label: "Disposition", key: "disposition" },
      { label: "Notes", key: "notes" }
    ];

    if (this.isUserJudge()) {
      headers.push({ label: "AOD", key: "aod" });
    }

    return headers;
  }

  render() {
    const { dailyDocket, openModal, onDisplayLockModal, hearings, onClickRemoveHearingDay, user } = this.props;
    const formattedScheduledForDate = moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY');

    return <React.Fragment>
      <h1>Daily Docket ({formattedScheduledForDate})</h1><br />
      <div {...css({
        marginTop: '-35px',
        marginBottom: '25px'
      })}>
        <Link linkStyling to="/schedule" >&lt; Back to schedule</Link>&nbsp;&nbsp;
        {user.userRoleAssign &&
          <span>
            <EditHearingDayLink openModal={openModal} />
            &nbsp;&nbsp;
            <LockHearingLink dailyDocket={dailyDocket} onDisplayLockModal={onDisplayLockModal} />
            &nbsp;&nbsp;
          </span>}
        {(_.isEmpty(hearings) && user.userRoleBuild) &&
          <RemoveHearingDayLink onClickRemoveHearingDay={onClickRemoveHearingDay} />}

        {dailyDocket.notes &&
          <span {...css({ marginTop: '15px' })}>
            <br /><strong>Notes: </strong><br />{dailyDocket.notes}
          </span>}
      </div>
      <div>
        <CSVLink
          data={this.exportDailyDocket()}
          headers={this.getExportDailyDocketHeaders()}
          target="_blank"
          filename={`Daily Docket ${formattedScheduledForDate}.csv`}
        >
          <Button classNames={['usa-button-secondary']}>
            Download & Print Page
          </Button>
        </CSVLink>
      </div>
    </React.Fragment>;
  }
}

DailyDocketEditLinks.propTypes = {
  dailyDocket: PropTypes.object.isRequired,
  hearings: PropTypes.arrayOf(PropTypes.object).isRequired,
  openModal: PropTypes.func.isRequired,
  onDisplayLockModal: PropTypes.func.isRequired,
  onClickRemoveHearingDay: PropTypes.func.isRequired,
  user: PropTypes.object.isRequired
};
