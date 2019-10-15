import React from 'react';
import PropTypes from 'prop-types';
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
import VirtualHearingModal from './VirtualHearingModal';

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
    readableLocation, disposition, readableRequestType, hearingDayId, aod
  }
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

Overview.propTypes = {
  hearing: PropTypes.shape({
    scheduledFor: PropTypes.string,
    docketName: PropTypes.string,
    docketNumber: PropTypes.string,
    regionalOfficeName: PropTypes.string,
    readableLocation: PropTypes.string,
    disposition: PropTypes.string,
    readableRequestType: PropTypes.string,
    hearingDayId: PropTypes.number,
    aod: PropTypes.bool
  })
};

const Details = ({
  hearing, update, readOnly, isLegacy, openModal, updateVirtualHearing, virtualHearing,
  enableVirtualHearings
}) => (
  <React.Fragment>
    <div {...rowThirds}>
      {enableVirtualHearings && <SearchableDropdown
        label="Hearing Type"
        name="hearing-type"
        strongLabel
        options={[
          {
            value: false,
            label: 'Video'
          },
          {
            value: true,
            label: 'Virtual'
          }
        ]}
        value={virtualHearing.active || false}
        onChange={(option) => {
          if (virtualHearing.active || option.value) {
            openModal();
          }
          updateVirtualHearing({ active: option.value });
        }}
      />}
    </div>
    <div {...rowThirds}>
      <JudgeDropdown
        name="judgeDropdown"
        value={hearing.judgeId}
        readOnly={readOnly}
        onChange={(judgeId) => update({ judgeId })}
      />
    </div>
    <div {...rowThirds}>
      <HearingRoomDropdown
        name="hearingRoomDropdown"
        value={hearing.room}
        readOnly={readOnly}
        onChange={(room) => update({ room })}
      />
      <HearingCoordinatorDropdown
        name="hearingCoordinatorDropdown"
        value={hearing.bvaPoc}
        readOnly={readOnly}
        onChange={(bvaPoc) => update({ bvaPoc })}
      />
      {!isLegacy &&
        <div>
          <strong>Waive 90 Day Evidence Hold</strong>
          <Checkbox
            label="Yes, Waive 90 Day Evidence Hold"
            name="evidenceWindowWaived"
            disabled={readOnly}
            value={hearing.evidenceWindowWaived || false}
            onChange={(evidenceWindowWaived) => update({ evidenceWindowWaived })}
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
      value={hearing.notes || ''}
      onChange={(notes) => update({ notes })}
    />
  </React.Fragment>
);

Details.propTypes = {
  hearing: PropTypes.shape({
    judgeId: PropTypes.string,
    room: PropTypes.string,
    evidenceWindowWaived: PropTypes.bool,
    notes: PropTypes.string,
    bvaPoc: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool,
  isLegacy: PropTypes.bool,
  openModal: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    active: PropTypes.bool
  }),
  enableVirtualHearings: PropTypes.bool
};

const TranscriptionDetails = ({ transcription, update, readOnly }) => (
  <React.Fragment>
    <div {...rowThirds}>
      <TextField
        name="taskNumber"
        label="Task #"
        strongLabel
        readOnly={readOnly}
        value={transcription.taskNumber}
        onChange={(taskNumber) => update({ taskNumber })}
      />
      <SearchableDropdown
        name="transcriber"
        label="Transcriber"
        strongLabel
        readOnly={readOnly}
        value={transcription.transcriber}
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
        onChange={(option) => update({ transcriber: (option || {}).value })}
      />
    </div>
    <div {...rowThirds}>
      <DateSelector
        name="sentToTranscriberDate"
        label="Sent to Transcriber"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={transcription.sentToTranscriberDate}
        onChange={(sentToTranscriberDate) => update({ sentToTranscriberDate })}
      />
      <DateSelector
        name="expectedReturnDate"
        label="Expected Return Date"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={transcription.expectedReturnDate}
        onChange={(expectedReturnDate) => update({ expectedReturnDate })}
      />
      <DateSelector
        name="uploadedToVbmsDate"
        label="Transcript Uploaded to VBMS"
        strongLabel
        type="date"
        readOnly={readOnly}
        value={transcription.uploadedToVbmsDate}
        onChange={(uploadedToVbmsDate) => update({ uploadedToVbmsDate })}
      />
    </div>
  </React.Fragment>
);

TranscriptionDetails.propTypes = {
  transcription: PropTypes.shape({
    taskNumber: PropTypes.string,
    transcriber: PropTypes.string,
    sentToTranscriberDate: PropTypes.string,
    expectedReturnDate: PropTypes.string,
    uploadedToVbmsDate: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

const TranscriptionProblem = ({ transcription, update, readOnly }) => (
  <div {...rowThirds}>
    <SearchableDropdown
      name="problemType"
      label="Transcription Problem Type"
      strongLabel
      readOnly={readOnly}
      value={transcription.problemType}
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
      onChange={(option) => update({ problemType: (option || {}).value })}
    />
    <DateSelector
      name="problemNoticeSentDate"
      label="Problem Notice Sent"
      strongLabel
      type="date"
      readOnly={readOnly || _.isEmpty(transcription.problemType)}
      value={transcription.problemNoticeSentDate}
      onChange={(problemNoticeSentDate) => update({ problemNoticeSentDate })}
    />
    <RadioField
      name="requestedRemedy"
      label="Requested Remedy"
      strongLabel
      options={[
        {
          value: '',
          displayText: 'None',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'Proceed without transcript',
          displayText: 'Proceeed without transcript',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'Proceed with partial transcript',
          displayText: 'Process with partial transcript',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        },
        {
          value: 'New hearing',
          displayText: 'New hearing',
          disabled: readOnly || _.isEmpty(transcription.problemType)
        }
      ]}
      value={transcription.requestedRemedy || ''}
      onChange={(requestedRemedy) => update({ requestedRemedy })}
    />
  </div>
);

TranscriptionProblem.propTypes = {
  transcription: PropTypes.shape({
    problemType: PropTypes.string,
    problemNoticeSentDate: PropTypes.string,
    requestedRemedy: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

const TranscriptionRequest = ({ hearing, update, readOnly }) => (
  <div {...rowThirds}>
    <div>
      <strong>Copy Requested by Appellant/Rep</strong>
      <Checkbox
        name="copyRequested"
        label="Yes, Transcript Requested"
        value={hearing.transcriptRequested || false}
        disabled={readOnly}
        onChange={(transcriptRequested) => update({ transcriptRequested })}
      />
    </div>
    <DateSelector
      name="copySentDate"
      label="Copy Sent to Appellant/Rep"
      strongLabel
      type="date"
      readOnly={readOnly}
      value={hearing.transcriptSentDate}
      onChange={(transcriptSentDate) => update({ transcriptSentDate })}
    />
  </div>
);

TranscriptionRequest.propTypes = {
  hearing: PropTypes.shape({
    transcriptRequested: PropTypes.bool,
    transcriptSentDate: PropTypes.string
  }),
  update: PropTypes.func,
  readOnly: PropTypes.bool
};

class Sections extends React.Component {

  constructor (props) {
    super(props);

    this.state = {
      modalOpen: false
    };
  }

  openModal = () => this.setState({ modalOpen: true })
  closeModal = () => this.setState({ modalOpen: false })

  resetVirtualHearing = () => {
    const { initialHearingState: { virtualHearing } } = this.props;

    if (virtualHearing) {
      const { veteranEmail, representativeEmail } = virtualHearing;

      this.props.updateVirtualHearing({
        veteranEmail,
        representativeEmail
      });
    } else {
      this.props.updateVirtualHearing(null);
    }

    this.closeModal();
  }

  render () {
    const {
      transcription, hearing, disabled, updateHearing, updateTranscription, updateVirtualHearing,
      isLegacy, virtualHearing, submit, user
    } = this.props;
    const { modalOpen } = this.state;

    return (
      <React.Fragment>
        <Details
          openModal={this.openModal}
          hearing={hearing}
          update={updateHearing}
          enableVirtualHearings={true || user.userCanScheduleVirtualHearings}
          virtualHearing={virtualHearing}
          updateVirtualHearing={updateVirtualHearing}
          readOnly={disabled}
          isLegacy={isLegacy} />
        <div className="cf-help-divider" />
        {modalOpen && <VirtualHearingModal
          hearing={hearing}
          virtualHearing={virtualHearing}
          update={updateVirtualHearing}
          submit={() => submit().then(this.closeModal)}
          reset={this.resetVirtualHearing} />}
        {!isLegacy &&
          <div>
            <h2>Transcription Details</h2>
            <TranscriptionDetails
              transcription={transcription}
              update={updateTranscription}
              readOnly={disabled} />
            <div className="cf-help-divider" />

            <h2>Transcription Problem</h2>
            <TranscriptionProblem
              transcription={transcription}
              update={updateTranscription}
              readOnly={disabled} />
            <div className="cf-help-divider" />

            <h2>Transcription Request</h2>
            <TranscriptionRequest
              hearing={hearing}
              update={updateHearing}
              readOnly={disabled} />
            <div className="cf-help-divider" />
          </div>
        }
      </React.Fragment>
    );
  }
}

Sections.propTypes = {
  transcription: PropTypes.object,
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  initialHearingState: PropTypes.shape({
    virtualHearing: PropTypes.shape({
      veteranEmail: PropTypes.string,
      representativeEmail: PropTypes.string,
      active: PropTypes.bool
    })
  }),
  disabled: PropTypes.bool,
  updateHearing: PropTypes.func,
  updateTranscription: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  isLegacy: PropTypes.bool,
  submit: PropTypes.func,
  user: PropTypes.shape({
    userCanScheduleVirtualHearings: PropTypes.bool
  })
};

export default Sections;
