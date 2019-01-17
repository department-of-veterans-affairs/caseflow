import React from 'react';
import { css } from 'glamor';
import * as DateUtil from '../../util/DateUtil';

import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from './DataDropdowns/index';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';
import TextField from '../../components/TextField';
import SearchableDropdown from '../../components/SearchableDropdown';
import DateSelector from '../../components/DateSelector';
import RadioField from '../../components/RadioField';

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
    scheduledFor, docketNumber, regionalOfficeName,
    readableLocation, disposition, readableRequestType,
    aod }
}) => (
  <DetailsOverview columns={[
    {
      label: 'Hearing Date',
      value: DateUtil.formatDateStr(scheduledFor)
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

export const Details = ({
  hearing: { judgeId, room, evidenceWindowWaived, notes, bvaPoc },
  set, readOnly
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      <JudgeDropdown
        value={judgeId}
        readOnly={readOnly}
        onChange={(val) => set('judgeId', val)}
      />
    </div>
    <div {...rowThirds}>
      <HearingRoomDropdown
        value={room}
        readOnly={readOnly}
        onChange={(val) => set('room', val)}
      />
      <HearingCoordinatorDropdown
        value={bvaPoc}
        readOnly={readOnly}
        onChange={(val) => set('bvaPoc', val)}
      />
      <div>
        <strong>Waive 90 Day Evidence Hold</strong>
        <Checkbox
          label="Yes, Waive 90 Day Evidence Hold"
          name="evidenceWindowWaived"
          readOnly={readOnly}
          value={evidenceWindowWaived}
          onChange={(val) => set('evidenceWindowWaived', val)}
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
      readOnly={readOnly}
      value={notes || ''}
      onChange={(val) => set('notes', val)}
    />
  </React.Fragment>
);

export const TranscriptionDetails = ({
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
        onChange={(val) => set('transcriber', val)}
      />
    </div>
    <div {...rowThirds}>
      <DateSelector
        name="sentToTranscriberDate"
        label="Sent to Transcriber"
        strongLabel
        readOnly={readOnly}
        value={sentToTranscriberDate}
        onChange={(val) => set('sentToTranscriberDate', val)}
      />
      <DateSelector
        name="expectedReturnDate"
        label="Expected Return Date"
        strongLabel
        readOnly={readOnly}
        value={expectedReturnDate}
        onChange={(val) => set('expectedReturnDate', val)}
      />
      <DateSelector
        name="uploadedToVbmsDate"
        label="Transcript Uploaded to VBMS"
        strongLabel
        readOnly={readOnly}
        value={uploadedToVbmsDate}
        onChange={(val) => set('uploadedToVbmsDate', val)}
      />
    </div>
  </React.Fragment>
);

export const TranscriptionProblem = ({
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
      onChange={(val) => set('problemType', val)}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      readOnly={readOnly}
      value={problemNoticeSentDate}
      onChange={(val) => set('problemNoticeSentDate', val)}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      readOnly={readOnly}
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

export const TranscriptionRequest = ({
  transcription: { copyRequested, copySentDate },
  set, readOnly
}) => (
  <div {...rowThirds}>
    <div>
      <strong>Copy Requested by Appellant/Rep</strong>
      <Checkbox
        name="copyRequested"
        label="Yes, Transcript Requested"
        value={copyRequested}
        readOnly={readOnly}
        onChange={(val) => set('copyRequested', val)}
      />
    </div>
    <DateSelector
      name="copySentDate"
      label="Copy Sent to Appellant/Rep"
      strongLabel
      readOnly={readOnly}
      value={copySentDate}
      onChange={(val) => set('copySentDate', val)}
    />
  </div>
);
