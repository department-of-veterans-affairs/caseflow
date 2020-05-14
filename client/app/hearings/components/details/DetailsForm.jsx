import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { EmailNotificationHistory } from './EmailNotificationHistory';
import { HearingLinks } from './HearingLinks';
import {
  HearingsFormContext,
  UPDATE_HEARING_DETAILS, UPDATE_TRANSCRIPTION, UPDATE_VIRTUAL_HEARING
} from '../../contexts/HearingsFormContext';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import {
  VIRTUAL_HEARING_HOST,
  getAppellantTitleForHearing,
  virtualHearingRoleForUser
} from '../../utils';
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

// Displays the emails associated with the virtual hearing.
const EmailSection = (
  { hearing, virtualHearing, isVirtual, wasVirtual, readOnly, dispatch, errors }
) => {
  const showEmailFields = (isVirtual || wasVirtual) && virtualHearing;

  if (!showEmailFields) {
    return null;
  }

  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || wasVirtual || hearing.scheduledForIsPast;
  const appellantTitle = getAppellantTitleForHearing(hearing);

  return (
    <div {...rowThirdsWithFinalSpacer}>
      <TextField
        errorMessage={errors?.appellantEmail}
        name={`${appellantTitle} Email for Notifications`}
        value={virtualHearing.appellantEmail}
        strongLabel
        className={[
          classnames('cf-form-textinput', 'cf-inline-field', {
            [enablePadding]: errors?.appellantEmail
          })
        ]}
        readOnly={readOnlyEmails}
        onChange={(appellantEmail) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: { appellantEmail } })}
        inputStyling={maxWidthFormInput}
      />
      <TextField
        errorMessage={errors?.repEmail}
        name="POA/Representative Email for Notifications"
        value={virtualHearing.representativeEmail}
        strongLabel
        className={[classnames('cf-form-textinput', 'cf-inline-field')]}
        readOnly={readOnlyEmails}
        onChange={(representativeEmail) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: { representativeEmail } })}
        inputStyling={maxWidthFormInput}
      />
      <div />
    </div>
  );
};

EmailSection.propTypes = {
  dispatch: PropTypes.func,
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  hearing: PropTypes.shape({
    appellantIsNotVeteran: PropTypes.bool,
    scheduledForIsPast: PropTypes.bool
  }),
  virtualHearing: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  readOnly: PropTypes.bool
};

// Displays the virtual hearing link and emails.
const VirtualHearingSection = (
  { hearing, virtualHearing, isVirtual, wasVirtual, readOnly, dispatch, errors }
) => {
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
        dispatch={dispatch}
      />
    </React.Fragment>
  );
};

VirtualHearingSection.propTypes = {
  dispatch: PropTypes.func,
  hearing: PropTypes.object,
  isVirtual: PropTypes.bool,
  readOnly: PropTypes.bool,
  virtualHearing: PropTypes.shape({
    jobCompleted: PropTypes.bool
  }),
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  wasVirtual: PropTypes.bool
};

// Displays transcriptions fields.
const TranscriptionSection = ({ hearing, transcription, readOnly, dispatch }) => (
  <React.Fragment>
    <div className="cf-help-divider" />
    <div>
      <h2>Transcription Details</h2>
      <TranscriptionDetailsInputs
        transcription={transcription}
        update={(values) => dispatch({ type: UPDATE_TRANSCRIPTION, payload: values })}
        readOnly={readOnly}
      />
      <div className="cf-help-divider" />

      <h3>Transcription Problem</h3>
      <TranscriptionProblemInputs
        transcription={transcription}
        update={(values) => dispatch({ type: UPDATE_TRANSCRIPTION, payload: values })}
        readOnly={readOnly}
      />
      <div className="cf-help-divider" />

      <h3>Transcription Request</h3>
      <TranscriptionRequestInputs
        hearing={hearing}
        update={(values) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: values })}
        readOnly={readOnly}
      />
      <div className="cf-help-divider" />
    </div>
  </React.Fragment>
);

TranscriptionSection.propTypes = {
  dispatch: PropTypes.func,
  hearing: PropTypes.object,
  readOnly: PropTypes.bool,
  transcription: PropTypes.object
};

const DetailsForm = (props) => {
  const {
    isLegacy,
    isVirtual,
    openVirtualHearingModal,
    readOnly,
    requestType,
    wasVirtual,
    errors,
    updateVirtualHearing
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);
  const enableVirtualHearings = userCanScheduleVirtualHearings && requestType !== 'Central';
  const { state: { hearingForms }, dispatch } = useContext(HearingsFormContext);
  const { hearingDetailsForm, virtualHearingForm, transcriptionDetailsForm } = hearingForms;

  return (
    <React.Fragment>
      <div {...rowThirds}>
        <JudgeDropdown
          name="judgeDropdown"
          value={hearingDetailsForm?.judgeId}
          readOnly={readOnly}
          onChange={(judgeId) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { judgeId } })}
        />
        <HearingCoordinatorDropdown
          name="hearingCoordinatorDropdown"
          value={hearingDetailsForm?.bvaPoc}
          readOnly={readOnly}
          onChange={(bvaPoc) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { bvaPoc } })}
        />
        <HearingRoomDropdown
          name="hearingRoomDropdown"
          value={hearingDetailsForm?.room}
          readOnly={readOnly}
          onChange={(room) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { room } })}
        />
      </div>
      {enableVirtualHearings && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <div {...flexParent}>
            <HearingTypeDropdown
              virtualHearing={virtualHearingForm}
              requestType={requestType}
              updateVirtualHearing={updateVirtualHearing}
              openModal={openVirtualHearingModal}
              readOnly={
                hearingDetailsForm?.scheduledForIsPast ||
                ((isVirtual || wasVirtual) &&
                !virtualHearingForm?.jobCompleted)
              }
              styling={columnThird}
            />
            <div {...columnDoubleSpacer} />
          </div>
        </React.Fragment>
      )}
      <VirtualHearingSection
        errors={errors}
        hearing={hearingDetailsForm}
        isVirtual={isVirtual}
        readOnly={readOnly}
        virtualHearing={virtualHearingForm}
        wasVirtual={wasVirtual}
        dispatch={dispatch}
      />
      {hearingDetailsForm?.emailEvents.length > 0 &&
        <EmailNotificationHistory rows={hearingDetailsForm?.emailEvents} />}
      {!isLegacy && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <div>
            <strong>Waive 90 Day Evidence Hold</strong>
            <Checkbox
              label="Yes, Waive 90 Day Evidence Hold"
              name="evidenceWindowWaived"
              disabled={readOnly}
              value={hearingDetailsForm?.evidenceWindowWaived || false}
              onChange={(evidenceWindowWaived) => dispatch(
                { type: UPDATE_HEARING_DETAILS, payload: { evidenceWindowWaived } }
              )}
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
        value={hearingDetailsForm?.notes || ''}
        onChange={(notes) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { notes } })}
      />
      {!isLegacy && (
        <TranscriptionSection
          hearing={hearingDetailsForm}
          readOnly={readOnly}
          transcription={transcriptionDetailsForm}
          dispatch={dispatch}
        />
      )}
    </React.Fragment>
  );
};

DetailsForm.propTypes = {
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string
  }),
  isLegacy: PropTypes.bool,
  isVirtual: PropTypes.bool,
  openVirtualHearingModal: PropTypes.func,
  readOnly: PropTypes.bool,
  requestType: PropTypes.string,
  updateVirtualHearing: PropTypes.func,
  wasVirtual: PropTypes.bool
};

export default DetailsForm;
