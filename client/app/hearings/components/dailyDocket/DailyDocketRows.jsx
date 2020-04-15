import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { sortHearings } from '../../utils';
import DailyDocketRow from './DailyDocketRow';
import { docketRowStyle } from './style';

const rowsMargin = css({
  marginLeft: '-40px',
  marginRight: '-40px',
  marginBottom: '-40px'
});

const Header = ({ user }) => (
  <div {...docketRowStyle}
    {...css({
      '& *': {
        background: 'none !important'
      },
      '& > div > div': { verticalAlign: 'bottom' }
    })} className={user.userHasHearingPrepRole ? 'judge-view' : ''}>
    <div>
      <div>{user.userHasHearingPrepRole && <strong>Prep</strong>}</div>
      <div></div>
      <div><strong>Appellant/Veteran ID/Representative</strong></div>
      <div><strong>Type/Time/ROs</strong></div>
    </div>
    <div><div><strong>Actions</strong></div></div>
  </div>
);

Header.propTypes = {
  user: PropTypes.shape({
    userHasHearingPrepRole: PropTypes.bool
  })
};

export default class DailyDocketHearingRows extends React.Component {
  render () {
    const { hearings, readOnly, regionalOffice,
      openDispositionModal, user, saveHearing, hidePreviouslyScheduled } = this.props;

    const sortedHearings = sortHearings(hearings);

    return <div {...rowsMargin}>
      <Header user={user} />
      <div>{sortedHearings.map((hearing, index) => (
        <DailyDocketRow hearingId={hearing.externalId}
          index={index}
          readOnly={readOnly}
          hidePreviouslyScheduled={hidePreviouslyScheduled}
          user={user}
          saveHearing={saveHearing}
          regionalOffice={regionalOffice}
          openDispositionModal={openDispositionModal} />
      ))}</div>
    </div>;
  }
}

DailyDocketHearingRows.propTypes = {
  hearings: PropTypes.array,
  openDispositionModal: PropTypes.func,
  readOnly: PropTypes.bool,
  regionalOffice: PropTypes.string,
  saveHearing: PropTypes.func,
  hidePreviouslyScheduled: PropTypes.bool,
  user: PropTypes.shape({
    userHasHearingPrepRole: PropTypes.bool
  })
};
