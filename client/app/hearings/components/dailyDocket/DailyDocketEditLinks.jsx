import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from '../../../components/Button';
import { CrossIcon } from '../../../components/icons/fontAwesome/CrossIcon';
import { PencilIcon } from '../../../components/icons/PencilIcon';
import { LockIcon } from '../../../components/icons/LockIcon';

const EditHearingDayLink = ({ docketId, history }) => (
  <Button
    {...css({ marginLeft: '30px' })}
    linkStyling
    onClick={() => history.push(`/schedule/docket/${docketId}/edit`)}
  >
    <span {...css({ position: 'absolute' })}><PencilIcon size={25} /></span>
    <span {...css({ marginRight: '5px', marginLeft: '20px' })} >
      Edit Hearing Day
    </span>
  </Button>
);

EditHearingDayLink.propTypes = {
  history: PropTypes.object,
  docketId: PropTypes.string.isRequired
};

const LockHearingLink = ({ dailyDocket, onDisplayLockModal }) => (
  <Button linkStyling onClick={onDisplayLockModal}>
    <span {...css({ position: 'absolute',
      '& > svg > g > g': { fill: '#0071bc' } })}>
      <LockIcon />
    </span>
    <span {...css({ marginRight: '5px',
      marginLeft: '16px' })}>
      {dailyDocket.lock ? 'Unlock Hearing Day' : 'Lock Hearing Day'}
    </span>
  </Button>
);

LockHearingLink.propTypes = {
  dailyDocket: PropTypes.shape({
    lock: PropTypes.bool
  }),
  onDisplayLockModal: PropTypes.func.isRequired
};

const RemoveHearingDayLink = ({ onClickRemoveHearingDay }) => (
  <Button
    linkStyling
    onClick={onClickRemoveHearingDay} >
    <CrossIcon /><span{...css({ marginLeft: '3px' })}>Remove Hearing Day</span>
  </Button>
);

RemoveHearingDayLink.propTypes = {
  onClickRemoveHearingDay: PropTypes.func.isRequired
};

export default class DailyDocketEditLinks extends React.Component {

  render() {
    const { dailyDocket, onDisplayLockModal, hearings, onClickRemoveHearingDay, user } = this.props;

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
            <EditHearingDayLink {...this.props} docketId={dailyDocket?.id} />
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
