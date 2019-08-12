import React from 'react';
import { css } from 'glamor';
import { sortHearings } from '../../utils';
import DailyDocketRow from './DailyDocketRow';

const docketRowStyle = css({
  borderBottom: '1px solid #ddd',
  '& > div': {
    display: 'inline-block',
    '& > div': {
      verticalAlign: 'top',
      display: 'inline-block',
      padding: '15px'
    }
  },
  '& > div:nth-child(1)': {
    width: '40%',
    '& > div:nth-child(1)': { width: '15%' },
    '& > div:nth-child(2)': { width: '5%' },
    '& > div:nth-child(3)': { width: '50%' },
    '& > div:nth-child(4)': { width: '25%' }
  },
  '& > div:nth-child(2)': {
    backgroundColor: '#f1f1f1',
    width: '60%',
    '& > div': { width: '50%' }
  },
  '&:not(.judge-view) > div:nth-child(1) > div:nth-child(1)': {
    display: 'none'
  }
});

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
      <div><strong>Time/RO(s)</strong></div>
    </div>
    <div><div><strong>Actions</strong></div></div>
  </div>
);

export default class DailyDocketHearingRows extends React.Component {
  render () {
    const { hearings, readOnly, regionalOffice,
      openDispositionModal, user, saveHearing } = this.props;

    const sortedHearings = sortHearings(hearings);

    return <div {...rowsMargin}>
      <Header user={user} />
      <div>{sortedHearings.map((hearing, index) => (
        <div {...docketRowStyle} key={hearing.externalId} className={user.userHasHearingPrepRole ? 'judge-view' : ''}>
          <DailyDocketRow hearingId={hearing.externalId}
            index={index}
            readOnly={readOnly}
            user={user}
            saveHearing={saveHearing}
            regionalOffice={regionalOffice}
            openDispositionModal={openDispositionModal} />
        </div>
      ))}</div>
    </div>;
  }
}
