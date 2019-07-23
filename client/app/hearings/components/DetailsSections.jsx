import React from 'react';
import { css } from 'glamor';
import { Link } from 'react-router-dom';
import _ from 'lodash';

import * as DateUtil from '../../util/DateUtil';

import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../components/DataDropdowns/index';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import TextField from '../../components/TextField';
import SearchableDropdown from '../../components/SearchableDropdown';
import DateSelector from '../../components/DateSelector';
import RadioField from '../../components/RadioField';
import DocketTypeBadge from '../../components/DocketTypeBadge';

import DetailsOverview from './DetailsOverview';

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

export const Overview = ({
  hearing: {
    scheduledFor, docketName, docketNumber, regionalOfficeName,
    readableLocation, disposition, readableRequestType, hearingDayId,
    aod }
}) => (
  <DetailsOverview columns={[
    {
      label: 'Hearing Date',
      value: readableRequestType === 'Travel' ? <strong>{DateUtil.formatDateStr(scheduledFor)}</strong> :
        <Link to={`/schedule/docket/${hearingDayId}`}>
          <strong>{DateUtil.formatDateStr(scheduledFor)}</strong>
        </Link>
    },
    {
      label: 'Docket Number',
      value: <span>
        <DocketTypeBadge name={docketName} number={docketNumber} />{docketNumber}
      </span>
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
      value: aod || 'None'
    }
  ]} />
);

const Details = ({
  hearing: { judgeId, room, evidenceWindowWaived, notes, bvaPoc },
  set, readOnly, isLegacy
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      <JudgeDropdown
        name="judgeDropdown"
        value={judgeId}
        readOnly={readOnly}
        onChange={(val) => set('judgeId', val)}
      />
    </div>
    <div {...rowThirds}>
      <HearingRoomDropdown
        name="hearingRoomDropdown"
        value={room}
        readOnly={readOnly}
        onChange={(val) => set('room', val)}
      />
      <HearingCoordinatorDropdown
        name="hearingCoordinatorDropdown"
        value={bvaPoc}
        readOnly={readOnly}
        onChange={(val) => set('bvaPoc', val)}
      />
      {!isLegacy &&
        <div>
          <strong>Waive 90 Day Evidence Hold</strong>
          <Checkbox
            label="Yes, Waive 90 Day Evidence Hold"
            name="evidenceWindowWaived"
            disabled={readOnly}
            value={evidenceWindowWaived || false}
            onChange={(val) => set('evidenceWindowWaived', val)}
          />
        </div>
      }
    </div>
    <TextareaField
      name="Notes"
      strongLabel
      styling={css({
        display: 'block',
        maxWidth: '100%'
      })}
      disabled={readOnly}
      value={notes || ''}
      onChange={(val) => set('notes', val)}
    />
  </React.Fragment>
);

const TranscriptionDetails = ({
  transcription: { taskNumber, transcriber, sentToTranscriberDate, expectedReturnDate, uploadedToVbmsDate },
  set, readOnly
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      <TextField
        name="taskNumber"
        label="Task #"
        strongLabel
        readOnly={readOnly}
        value={taskNumber}
        onChange={(val) => set('taskNumber', val)}
      />
      <SearchableDropdown
        name="transcriber"
        label="Transcriber"
        strongLabel
        readOnly={readOnly}
        value={transcriber}
        options={[
          {
            label: '',
            value: null
          },
          {
            label: 'Genesis Government Solutions, Inc.',
            value: 'Genesis Government Solutions, Inc.'
          },
          {
            label: 'Jamison Professional Services',
            value: 'Jamison Professional Services'
          },
          {
            label: 'The Ravens Group, Inc.',
            value: 'The Ravens Group, Inc.'
          }
        ]}
        onChange={(val) => set('transcriber', (val || {}).value)}
      />
    </div>
    <div {...rowThirds}>
      <DateSelector
        name="sentToTranscriberDate"
        label="Sent to Transcriber"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={sentToTranscriberDate}
        onChange={(val) => set('sentToTranscriberDate', val)}
      />
      <DateSelector
        name="expectedReturnDate"
        label="Expected Return Date"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={expectedReturnDate}
        onChange={(val) => set('expectedReturnDate', val)}
      />
      <DateSelector
        name="uploadedToVbmsDate"
        label="Transcript Uploaded to VBMS"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={uploadedToVbmsDate}
        onChange={(val) => set('uploadedToVbmsDate', val)}
      />
    </div>
  </React.Fragment>
);

const TranscriptionProblem = ({
  transcription: { problemType, problemNoticeSentDate, requestedRemedy },
  set, readOnly
}) => (
  <div {...rowThirds}>
    <SearchableDropdown
      name="problemType"
      label="Transcription Problem Type"
      strongLabel
      readOnly={readOnly}
      value={problemType}
      options={[
        {
          label: '',
          value: null
        },
        {
          label: 'No audio',
          value: 'No audio'
        },
        {
          label: 'Poor Audio Quality',
          value: 'Poor Audio Quality'
        },
        {
          label: 'Incomplete Hearing',
          value: 'Incomplete Hearing'
        },
        {
          label: 'Other (see notes)',
          value: 'Other (see notes)'
        }
      ]}
      onChange={(val) => set('problemType', (val || {}).value)}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      type="date"
      readOnly={readOnly || _.isEmpty(problemType)}
      value={problemNoticeSentDate}
      onChange={(val) => set('problemNoticeSentDate', val)}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      options={[
        {
          value: '',
          displayText: 'None',
          disabled: readOnly || _.isEmpty(problemType)
        },
        {
          value: 'Proceed without transcript',
          displayText: 'Proceeed without transcript',
          disabled: readOnly || _.isEmpty(problemType)
        },
        {
          value: 'Proceed with partial transcript',
          displayText: 'Process with partial transcript',
          disabled: readOnly || _.isEmpty(problemType)
        },
        {
          value: 'New hearing',
          displayText: 'New hearing',
          disabled: readOnly || _.isEmpty(problemType)
        }
      ]}
      value={requestedRemedy || ''}
      onChange={(val) => set('requestedRemedy', val)}
    />
  </div>
);

const TranscriptionRequest = ({
  hearing: { transcriptRequested, transcriptSentDate },
  set, readOnly
}) => (
  <div {...rowThirds}>
    <div>
      <strong>Copy Requested by Appellant/Rep</strong>
      <Checkbox
        name="copyRequested"
        label="Yes, Transcript Requested"
        value={transcriptRequested || false}
        disabled={readOnly}
        onChange={(val) => set('transcriptRequested', val)}
      />
    </div>
    <DateSelector
      name="copySentDate"
      label="Copy Sent to Appellant/Rep"
      strongLabel
      type="date"
      readOnly={readOnly}
      value={transcriptSentDate}
      onChange={(val) => set('transcriptSentDate', val)}
    />
  </div>
);

const Sections = ({ transcription, hearing, disabled, setHearing, setTranscription, isLegacy }) => (
  <React.Fragment>
    <Details
      hearing={hearing}
      set={setHearing}
      readOnly={disabled}
      isLegacy={isLegacy} />
    <div className="cf-help-divider" />

    {!isLegacy &&
      <div>
        <h2>Transcription Details</h2>
        <TranscriptionDetails
          transcription={transcription}
          set={setTranscription}
          readOnly={disabled} />
        <div className="cf-help-divider" />

        <h2>Transcription Problem</h2>
        <TranscriptionProblem
          transcription={transcription}
          set={setTranscription}
          readOnly={disabled} />
        <div className="cf-help-divider" />

        <h2>Transcription Request</h2>
        <TranscriptionRequest
          hearing={hearing}
          set={setHearing}
          readOnly={disabled} />
        <div className="cf-help-divider" />
      </div>
    }
  </React.Fragment>
);

export default Sections;
