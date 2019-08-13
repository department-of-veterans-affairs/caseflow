import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../../components/Button';
import { crossSymbolHtml, pencilSymbol, lockIcon } from '../../../components/RenderFunctions';

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

EditHearingDayLink.propTypes = {
  openModal: PropTypes.func.isRequired
};

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

LockHearingLink.propTypes = {
  dailyDocket: {
    lock: PropTypes.bool
  },
  onDisplayLockModal: PropTypes.func.isRequired
};

const RemoveHearingDayLink = ({ onClickRemoveHearingDay }) => (
  <Button
    linkStyling
    onClick={onClickRemoveHearingDay} >
    {crossSymbolHtml()}<span{...css({ marginLeft: '3px' })}>Remove Hearing Day</span>
  </Button>
);

RemoveHearingDayLink.propTypes = {
  onClickRemoveHearingDay: PropTypes.func.isRequired
};

export default class DailyDocketEditLinks extends React.Component {

  render() {
    const { dailyDocket, openModal, onDisplayLockModal, hearings, onClickRemoveHearingDay, user } = this.props;

    return <React.Fragment>
      <h1>Daily Docket ({moment(dailyDocket.scheduledFor).format('ddd M/DD/YYYY')})</h1>
      <br />
      <div {...css({
        marginTop: '-35px',
        marginBottom: '25px'
      })}>
        <Link linkStyling to="/schedule" >&lt; Back to schedule</Link>&nbsp;&nbsp;
        {user.userCanAssignHearingSchedule &&
          <span>
            <EditHearingDayLink openModal={openModal} />
            &nbsp;&nbsp;
            <LockHearingLink dailyDocket={dailyDocket} onDisplayLockModal={onDisplayLockModal} />
            &nbsp;&nbsp;
          </span>}
        {(_.isEmpty(hearings) && user.userCanBuildHearingSchedule) &&
          <RemoveHearingDayLink onClickRemoveHearingDay={onClickRemoveHearingDay} />}

        {dailyDocket.notes &&
          <span {...css({ marginTop: '15px' })}>
            <br /><strong>Notes: </strong><br />{dailyDocket.notes}
          </span>}
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
