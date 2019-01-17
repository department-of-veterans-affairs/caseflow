import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
// import { Link } from 'react-router-dom';
import { css } from 'glamor';

import CopyTextButton from '../components/CopyTextButton';
import DetailsOverview from './components/DetailsOverview';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../util/DateUtil';
// import ApiUtil from '../util/ApiUtil';

import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from './components/DataDropdowns/index';
import Checkbox from '../components/Checkbox';
import TextareaField from '../components/TextareaField';
import TextField from '../components/TextField';
import Button from '../components/Button';
import SearchableDropdown from '../components/SearchableDropdown';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';

const row = css({
  marginLeft: '-15px',
  marginRight: '-15px',
  '& > *': {
    display: 'inline-block',
    paddingRight: '15px',
    paddingLeft: '15px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const rowThirds = css({
  marginTop: '30px',
  marginBottom: '30px',
  marginLeft: '-15px',
  marginRight: '-15px',
  '& > *': {
    display: 'inline-block',
    paddingLeft: '15',
    paddingRight: '15px',
    verticalAlign: 'top',
    margin: 0,
    width: '33.333333333333%'
  }
});

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const Overview = ({
  hearing: {
    scheduledFor, docketNumber, regionalOfficeName,
    readableLocation, disposition, readableRequestType,
    aod }
}) => (
  <DetailsOverview columns={[
    {
      label: 'Hearing Date',
      value: DateUtil.formatDate(scheduledFor)
    },
    {
      label: 'Docket Number',
      value: docketNumber
    },
    {
      label: 'Regional office',
      value: regionalOfficeName
    },
    {
      label: 'Hearing Location',
      value: readableLocation
    },
    {
      label: 'Disposition',
      value: disposition
    },
    {
      label: 'Type',
      value: readableRequestType
    },
    {
      label: 'AOD Status',
      value: aod
    }
  ]} />
);

const Details = ({
  hearing: { vlj, room, waiveEvidenceHold, notes, coordinator },
  set
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      <JudgeDropdown
        value={vlj}
        onChange={(val) => set('vlj', val)}
      />
    </div>
    <div {...rowThirds}>
      <HearingRoomDropdown
        value={room}
        onChange={(val) => set('room', val)}
      />
      <HearingCoordinatorDropdown
        value={coordinator}
        onChange={(val) => set('coordinator', val)}
      />
      <div>
        <strong>Waive 90 Day Evidence Hold</strong>
        <Checkbox
          label="Yes, Waive 90 Day Evidence Hold"
          name="waiveEvidenceHold"
          value={waiveEvidenceHold}
          onChange={(val) => set('waiveEvidenceHold', val)}
        />
      </div>
    </div>
    <TextareaField
      name="Notes"
      strongLabel
      styling={css({
        display: 'block',
        maxWidth: '100%'
      })}
      value={notes || ''}
      onChange={(val) => set('notes', val)}
    />
  </React.Fragment>
);

const TranscriptionDetails = ({
  transcription: { taskNumber, transcriber, sentToTranscriberDate, expectedReturnDate, uploadedToVbmsDate },
  set
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      <TextField
        name="taskNumber"
        label="Task #"
        strongLabel
        value={taskNumber}
        onChange={(val) => set('taskNumber', val)}
      />
      <SearchableDropdown
        name="transcriber"
        label="Transcriber"
        strongLabel
        value={transcriber}
        onChange={(val) => set('transcriber', val)}
      />
    </div>
    <div {...rowThirds}>
      <DateSelector
        name="sentToTranscriberDate"
        label="Sent to Transcriber"
        strongLabel
        value={sentToTranscriberDate}
        onChange={(val) => set('sentToTranscriberDate', val)}
      />
      <DateSelector
        name="expectedReturnDate"
        label="Expected Return Date"
        strongLabel
        value={expectedReturnDate}
        onChange={(val) => set('expectedReturnDate', val)}
      />
      <DateSelector
        name="uploadedToVbmsDate"
        label="Transcript Uploaded to VBMS"
        strongLabel
        value={uploadedToVbmsDate}
        onChange={(val) => set('uploadedToVbmsDate', val)}
      />
    </div>
  </React.Fragment>
);

const TranscriptionProblem = ({
  transcription: { problemType, problemNoticeSentDate, requestedRemedy },
  set
}) => (
  <div {...rowThirds}>
    <SearchableDropdown
      name="problemType"
      label="Transcription Problem Type"
      strongLabel
      value={problemType}
      onChange={(val) => set('problemType', val)}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      value={problemNoticeSentDate}
      onChange={(val) => set('problemNoticeSentDate', val)}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      options={[
        {
          value: 'Proceed without transcript',
          displayText: 'Proceeed without transcript'
        },
        {
          value: 'Proceed with partial transcript',
          displayText: 'Process with partial transcript'
        },
        {
          value: 'New hearing',
          displayText: 'New hearing'
        }
      ]}
      value={requestedRemedy}
      onChange={(val) => set('requestedRemedy', val)}
    />
  </div>
);

const TranscriptionRequest = ({
  transcription: { copyRequested, copySentDate },
  set
}) => (
  <div {...rowThirds}>
    <div>
      <strong>Copy Requested by Appellant/Rep</strong>
      <Checkbox
        name="copyRequested"
        label="Yes, Transcript Requested"
        value={copyRequested}
        onChange={(val) => set('copyRequested', val)}
      />
    </div>
    <DateSelector
      name="copySentDate"
      label="Copy Sent to Appellant/Rep"
      strongLabel
      value={copySentDate}
      onChange={(val) => set('copySentDate', val)}
    />
  </div>
);

class HearingDetails extends React.Component {

  constructor(props) {
    super(props);

    const { hearing } = this.props;

    this.state = {
      hearing: {
        vlj: hearing.judge ? hearing.judge.judgeCssId : null,
        coordinator: null,
        room: null,
        waiveEvidenceHold: false,
        notes: null
      },
      transcription: {
        // Transcription Details
        taskNumber: null,
        transcriber: null,
        sentToTranscriberDate: null,
        expectedReturnDate: null,
        uploadedToVbmsDate: null,
        // Transcription Problem
        problemType: null,
        problemNoticeSentDate: null,
        requestedRemedy: null,
        // Transcript Request
        copyRequested: false,
        copySentDate: null
      },
      updated: false,
      loading: false
    };
  }

  setHearing = (key, value) => {
    this.setState({
      hearing: {
        ...this.state.hearing,
        [key]: value
      },
      updated: true
    });
  }

  setTranscription = (key, value) => {
    this.setState({
      transcription: {
        ...this.state.transcription,
        [key]: value
      },
      updated: true
    });
  }

  // goBack = () => {
  //
  // }
  //
  // submit = () => {
  //
  // }

  render() {
    const {
      veteranFirstName,
      veteranLastName,
      vbmsId
    } = this.props.hearing;

    return (
      <AppSegment filledBackground>
        <div {...inputFix}>
          <div {...row}>
            <h1 className="cf-margin-bottom-0">{`${veteranFirstName} ${veteranLastName}`}</h1>
            <div>Veteran ID: <CopyTextButton text={vbmsId} /></div>
          </div>

          <div className="cf-help-divider" />

          <h2>Hearing Details</h2>
          <Overview hearing={this.props.hearing} />
          <div className="cf-help-divider" />

          <Details hearing={this.state.hearing} set={this.setHearing} />
          <div className="cf-help-divider" />

          <h2>Transcription Details</h2>
          <TranscriptionDetails transcription={this.state.transcription} set={this.setTranscription} />
          <div className="cf-help-divider" />

          <h2>Transcription Problem</h2>
          <TranscriptionProblem transcription={this.state.transcription} set={this.setTranscription} />
          <div className="cf-help-divider" />

          <h2>Transcription Request</h2>
          <TranscriptionRequest transcription={this.state.transcription} set={this.setTranscription} />
          <div className="cf-help-divider" />

          <div>
            <a
              className="button-link"
              onClick={this.goBack}
              style={{ float: 'left' }}
            >Cancel</a>
            <Button
              name="Save"
              loading={this.state.loading}
              className="usa-button"
              onClick={this.submit}
              styling={css({ float: 'right' })}
            />
          </div>
        </div>
      </AppSegment>
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired
};

export default connect(
  null
)(HearingDetails);
