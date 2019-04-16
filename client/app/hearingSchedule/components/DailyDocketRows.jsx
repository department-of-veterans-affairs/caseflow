import React from 'react';
import { css } from 'glamor';

import HearingActions from './DailyDocketRowActions';
import HearingText from './DailyDocketRowDisplayText';

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
    '& > div:nth-child(1)': { width: '10%' },
    '& > div:nth-child(2)': { width: '50%' },
    '& > div:nth-child(3)': { width: '40%' }
  },
  '& > div:nth-child(2)': {
    backgroundColor: '#f1f1f1',
    width: '60%',
    '& > div': { width: '50%' }
  }
});

const Header = () => (
  <div {...docketRowStyle}
    {...css({
      '& *': {
        background: 'none !important'
      },
      '& > div > div': { verticalAlign: 'bottom' }
    })}>
    <div>
      <div></div>
      <div><strong>Appellant/Veteran ID/Representative</strong></div>
      <div><strong>Time/RO(s)</strong></div>
    </div>
    <div><div><strong>Actions</strong></div></div>
  </div>
);

export default class DailyDocketHearingRows extends React.Component {

  updateHearingNotes = (hearing) => (value) => this.props.onHearingNotesUpdate(hearing.id, value)

  updateHearingDisposition = (hearing) => (value) => this.props.onHearingDispositionUpdate(hearing.id, value)

  updateHearingTime = (hearing) => (value) => this.props.onHearingTimeUpdate(hearing.id, value)

  updateTranscriptRequested = (hearing) => (value) => this.props.onTranscriptRequestedUpdate(hearing.id, value)

  updateHearingLocation = (hearing) => (value) => this.props.onHearingLocationUpdate(hearing.id, value)

  cancelHearingUpdate = (hearing) => () => this.props.cancelHearingUpdate(hearing)

  saveHearing = (hearing) => () => this.props.saveHearing(hearing.id);

  render () {
    const { hearings, readOnly, regionalOffice, openDispositionModal, user } = this.props;

    return <div>
      <Header />
      <div>{hearings.map((hearing, index) => (
        <div {...docketRowStyle} key={`docket-row-${index}`}><div>
          <HearingText
            hearing={hearing}
            index={index} />
        </div><div>
          <HearingActions hearing={hearing} readOnly={readOnly} user={user} regionalOffice={regionalOffice}
            openDispositionModal={openDispositionModal}
            updateHearingNotes={this.updateHearingNotes(hearing)}
            updateHearingDisposition={this.updateHearingDisposition(hearing)}
            updateHearingTime={this.updateHearingTime(hearing)}
            updateHearingLocation={this.updateHearingLocation(hearing)}
            updateTranscriptRequested={this.updateTranscriptRequested(hearing)}
            saveHearing={this.saveHearing(hearing)}
            cancelHearingUpdate={this.cancelHearingUpdate(hearing)} />
        </div></div>
      ))}</div>
    </div>;
  }
}
