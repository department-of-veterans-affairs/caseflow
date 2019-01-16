import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';
import { css } from 'glamor';

import CopyTextButton from '../components/CopyTextButton';
import DetailsOverview from './components/DetailsOverview';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../util/DateUtil';
import ApiUtil from '../util/ApiUtil';

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

const inlineRow = css({
  '& > *': {
    display: 'inline-block',
    paddingRight: '25px',
    verticalAlign: 'middle',
    margin: 0
  }
});

const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important'
  }
});

const inlineRowThirds = css({
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

class HearingDetails extends React.Component {

  constructor(props) {
    super(props);

    const { hearing } = this.props;

    this.state = {
      hearing: {
        vlj: hearing.judge.judgeCssId,
        hearingCoordinator: null,
        room: null,
        waiveEvidenceHold: null,
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
        // Transcript Requests
        copyRequested: null,
        copySentDate: null
      },
      loading: false
    };
  }

  updateHearing = (update) => {
    console.log(update);
    this.setState({
      hearing: {
        ...this.state.hearing,
        ...update
      }
    });
  }

  updateTranscription = (update) => {
    this.setState({
      transcription: {
        ...this.state.transcription,
        ...update
      }
    });
  }

  goBack = () => {

  }

  submit = () => {

  }

  overviewColumns = () => {

    const {
      scheduledFor,
      docketNumber,
      regionalOfficeName,
      //  hearing_location,
      disposition,
      readableRequestType,
      aod
    } = this.props.hearing;

    return [
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
        value: ' '
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
    ];
  }

  render() {
    const {
      veteranFirstName,
      veteranLastName,
      vbmsId
    } = this.props.hearing;

    console.log(this.props.hearing);

    return (
      <AppSegment filledBackground>
        <div {...inputFix}>
          <div {...inlineRow}>
            <h1 className="cf-margin-bottom-0">{`${veteranFirstName} ${veteranLastName}`}</h1>
            <div>Veteran ID: <CopyTextButton text={vbmsId} /></div>
          </div>

          <div className="cf-help-divider"></div>

          <h2>Hearing Details</h2>
          <DetailsOverview columns={this.overviewColumns()} />

          <div className="cf-help-divider"></div>

          <div {...inlineRowThirds}>
            <JudgeDropdown
              value={this.state.hearing.vlj}
              onChange={(vlj) => this.updateHearing({ vlj })}
            />
          </div>
          <div {...inlineRowThirds}>
            <HearingRoomDropdown
              value={this.state.hearing.room}
              onChange={(room) => this.updateHearing({ room })}
            />
            <HearingCoordinatorDropdown
              value={this.state.hearing.coordinator}
              onChange={(coordinator) => this.updateHearing({ coordinator })}
            />
            <div>
              <strong>Waive 90 Day Evidence Hold</strong>
              <Checkbox
                label="Yes, Waive 90 Day Evidence Hold"
                name="waiveEvidenceHold"
                value={this.state.hearing.waiveEvidenceHold}
                onChange={(waiveEvidenceHold) => this.updateHearing({ waiveEvidenceHold })}
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
            value={this.state.hearing.notes}
            onChange={(notes) => this.updateHearing({ notes })}
          />

          <div className="cf-help-divider"></div>

          <h2>Transcription Details</h2>
          <div {...inlineRowThirds}>
            <TextField
              name="taskNumber"
              label="Task #"
              strongLabel
              value={this.state.transcription.taskNumber}
              onChange={(taskNumber) => this.updateTranscription({ taskNumber })}
            />
            <SearchableDropdown
              name="transcriber"
              label="Transcriber"
              strongLabel
              value={this.state.transcription.transcriber}
              onChange={(transcriber) => this.updateTranscription({ transcriber })}
            />
          </div>
          <div {...inlineRowThirds}>
            <DateSelector
              name="sentToTranscriberDate"
              label="Sent to Transcriber"
              strongLabel
              value={this.state.transcription.sentToTranscriberDate}
              onChange={(sentToTranscriberDate) => this.updateTranscription({ sentToTranscriberDate })}
            />
            <DateSelector
              name="expectedReturnDate"
              label="Expected Return Date"
              strongLabel
              value={this.state.transcription.expectedReturnDate}
              onChange={(expectedReturnDate) => this.updateTranscription({ expectedReturnDate })}
            />
            <DateSelector
              name="uploadedToVbmsDate"
              label="Transcript Uploaded to VBMS"
              strongLabel
              value={this.state.transcription.uploadedToVbmsDate}
              onChange={(uploadedToVbmsDate) => this.updateTranscription({ uploadedToVbmsDate })}
            />
          </div>

          <div className="cf-help-divider"></div>

          <h2>Transcription Problem</h2>
          <div {...inlineRowThirds}>
            <SearchableDropdown
              name="problemType"
              label="Transcription Problem Type"
              strongLabel
              value={this.state.transcription.problemType}
              onChange={(problemType) => this.updateTranscription({ problemType })}
            />
            <DateSelector
              name="problemNoticeSentDate"
              label="Problem Notice Sent"
              strongLabel
              value={this.state.transcription.problemNoticeSentDate}
              onChange={(problemNoticeSentDate) => this.updateTranscription({ problemNoticeSentDate })}
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
              value={this.state.transcription.requestedRemedy}
              onChange={(requestedRemedy) => this.updateTranscription({ requestedRemedy })}
            />
          </div>

          <div className="cf-help-divider"></div>

          <h2>Transcription Request</h2>
          <div {...inlineRowThirds}>
            <div>
              <strong>Copy Requested by Appellant/Rep</strong>
              <Checkbox
                name="copyRequested"
                label="Yes, Transcript Requested"
                value={this.state.transcription.copyRequested}
                onChange={(copyRequested) => this.updateTranscription({ copyRequested })}
              />
            </div>
            <DateSelector
              name="copySentDate"
              label="Copy Sent to Appellant/Rep"
              strongLabel
              value={this.state.transcription.copySentDate}
              onChage={(copySentDate) => this.updateTranscription({ copySentDate })}
            />
          </div>

          <div className="cf-help-divider"></div>

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
