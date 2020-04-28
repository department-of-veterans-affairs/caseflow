import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { HearingsUserContext } from '../../HearingsUserContext';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import { VIRTUAL_HEARING_HOST, virtualHearingRoleForUser } from '../../utils';
import {
  columnDoubleSpacer,
  columnThird,
  flexParent,
  maxWidthFormInput,
  rowThirds,
  rowThirdsWithFinalSpacer,
  enablePadding
} from './style';
import COPY from '../../../../COPY';
import Checkbox from '../../../components/Checkbox';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextField from '../../../components/TextField';
import TextareaField from '../../../components/TextareaField';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';
import { HearingLinks } from './HearingLinks';
import { EmailNotificationHistory } from './EmailNotificationHistory';

// Displays the emails associated with the virtual hearing.

const EmailSection = ({ hearing, virtualHearing, isVirtual, wasVirtual, readOnly, updateVirtualHearing, errors }) => {
  const showEmailFields = (isVirtual || wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || wasVirtual || hearing.scheduledForIsPast;

  if (!showEmailFields) {
    return null;
  }

  return (
    <div {...rowThirdsWithFinalSpacer}>
      <TextField
        errorMessage={errors?.vetEmail}
        name="Veteran Email for Notifications"
        value={virtualHearing.veteranEmail}
        strongLabel
        className={[
          classnames('cf-form-textinput', 'cf-inline-field', {
            [enablePadding]: errors?.vetEmail
          })
        ]}
        readOnly={readOnlyEmails}
        onChange={(veteranEmail) => updateVirtualHearing({ veteranEmail })}
        inputStyling={maxWidthFormInput}
      />
      <TextField
        errorMessage={errors?.repEmail}
        name="POA/Representative Email for Notifications"
        value={virtualHearing.representativeEmail}
        strongLabel
        className={[classnames('cf-form-textinput', 'cf-inline-field')]}
        readOnly={readOnlyEmails}
        onChange={(representativeEmail) => updateVirtualHearing({ representativeEmail })}
        inputStyling={maxWidthFormInput}
      />
      <div />
    </div>
  );
};

EmailSection.propTypes = {
  errors: PropTypes.shape({
    vetEmail: PropTypes.string,
    repEmail: PropTypes.string
  }),
  hearing: PropTypes.shape({
    scheduledForIsPast: PropTypes.bool
  }),
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  readOnly: PropTypes.bool,
  updateVirtualHearing: PropTypes.func
};

// Displays the virtual hearing link and emails.
const VirtualHearingSection = ({
  hearing,
  virtualHearing,
  isVirtual,
  wasVirtual,
  readOnly,
  updateVirtualHearing,
  errors
}) => {
  if (!isVirtual && !wasVirtual) {
    return null;
  }

  const user = useContext(HearingsUserContext);
  const virtualHearingLabel =
    virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST ?
      COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL :
      COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;

  return (
    <React.Fragment>
      <div className="cf-help-divider" />
      <h3>{wasVirtual && 'Previous '}Virtual Hearing Details</h3>
      <HearingLinks
        user={user}
        label={virtualHearingLabel}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
      />
      <EmailSection
        errors={errors}
        hearing={hearing}
        virtualHearing={virtualHearing}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual}
        readOnly={readOnly}
        updateVirtualHearing={updateVirtualHearing}
      />
    </React.Fragment>
  );
};

VirtualHearingSection.propTypes = {
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  readOnly: PropTypes.bool,
  updateVirtualHearing: PropTypes.func,
  virtualHearing: PropTypes.shape({
    jobCompleted: PropTypes.bool
  }),
  errors: PropTypes.shape({
    vetEmail: PropTypes.string,
    repEmail: PropTypes.string
  }),
  wasVirtual: PropTypes.bool
};

// Displays transcriptions fields.
const TranscriptionSection = ({ hearing, updateHearing, transcription, updateTranscription, readOnly }) => (
  <React.Fragment>
    <div className="cf-help-divider" />
    <div>
      <h2>Transcription Details</h2>
      <TranscriptionDetailsInputs transcription={transcription} update={updateTranscription} readOnly={readOnly} />
      <div className="cf-help-divider" />

      <h3>Transcription Problem</h3>
      <TranscriptionProblemInputs transcription={transcription} update={updateTranscription} readOnly={readOnly} />
      <div className="cf-help-divider" />

      <h3>Transcription Request</h3>
      <TranscriptionRequestInputs hearing={hearing} update={updateHearing} readOnly={readOnly} />
      <div className="cf-help-divider" />
    </div>
  </React.Fragment>
);

TranscriptionSection.propTypes = {
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object,
  updateHearing: PropTypes.func,
  updateTranscription: PropTypes.func
};

const DetailsInputs = (props) => {
  const {
    hearing,
    isLegacy,
    isVirtual,
    openVirtualHearingModal,
    readOnly,
    requestType,
    transcription,
    updateHearing,
    updateTranscription,
    updateVirtualHearing,
    virtualHearing,
    wasVirtual,
    errors
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);
  const enableVirtualHearings = userCanScheduleVirtualHearings && requestType !== 'Central';

  return (
    <React.Fragment>
      <div {...rowThirds}>
        <JudgeDropdown
          name="judgeDropdown"
          value={hearing?.judgeId}
          readOnly={readOnly}
          onChange={(judgeId) => updateHearing({ judgeId })}
        />
        <HearingCoordinatorDropdown
          name="hearingCoordinatorDropdown"
          value={hearing?.bvaPoc}
          readOnly={readOnly}
          onChange={(bvaPoc) => updateHearing({ bvaPoc })}
        />
        <HearingRoomDropdown
          name="hearingRoomDropdown"
          value={hearing?.room}
          readOnly={readOnly}
          onChange={(room) => updateHearing({ room })}
        />
      </div>
      {enableVirtualHearings && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <div {...flexParent}>
            <HearingTypeDropdown
              virtualHearing={virtualHearing}
              requestType={requestType}
              updateVirtualHearing={updateVirtualHearing}
              openModal={openVirtualHearingModal}
              readOnly={hearing?.scheduledForIsPast || (isVirtual && !virtualHearing?.jobCompleted)}
              styling={columnThird}
            />
            <div {...columnDoubleSpacer} />
          </div>
        </React.Fragment>
      )}
      <VirtualHearingSection
        errors={errors}
        hearing={hearing}
        isVirtual={isVirtual}
        readOnly={readOnly}
        updateVirtualHearing={updateVirtualHearing}
        virtualHearing={virtualHearing}
        wasVirtual={wasVirtual}
      />
      {hearing?.emailEvents.length > 0 && <EmailNotificationHistory rows={hearing.emailEvents} />}
      {!isLegacy && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <div>
            <strong>Waive 90 Day Evidence Hold</strong>
            <Checkbox
              label="Yes, Waive 90 Day Evidence Hold"
              name="evidenceWindowWaived"
              disabled={readOnly}
              value={hearing?.evidenceWindowWaived || false}
              onChange={(evidenceWindowWaived) => updateHearing({ evidenceWindowWaived })}
            />
          </div>
        </React.Fragment>
      )}
      <div className="cf-help-divider" />
      <TextareaField
        name="Notes"
        strongLabel
        styling={maxWidthFormInput}
        disabled={readOnly}
        value={hearing?.notes || ''}
        onChange={(notes) => updateHearing({ notes })}
      />
      {!isLegacy && (
        <TranscriptionSection
          hearing={hearing}
          readOnly={readOnly}
          transcription={transcription}
          updateHearing={updateHearing}
          updateTranscription={updateTranscription}
        />
      )}
    </React.Fragment>
  );
};

DetailsInputs.propTypes = {
  errors: PropTypes.shape({
    vetEmail: PropTypes.string,
    repEmail: PropTypes.string
  }),
  hearing: PropTypes.shape({
    judgeId: PropTypes.string,
    room: PropTypes.string,
    evidenceWindowWaived: PropTypes.bool,
    notes: PropTypes.string,
    bvaPoc: PropTypes.string,
    scheduledForIsPast: PropTypes.bool,
    emailEvents: PropTypes.array
  }),
  readOnly: PropTypes.bool,
  requestType: PropTypes.string,
  isLegacy: PropTypes.bool,
  openVirtualHearingModal: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    status: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  enableVirtualHearings: PropTypes.bool,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  transcription: PropTypes.object,
  updateHearing: PropTypes.func,
  updateTranscription: PropTypes.func
};

export default DetailsInputs;
