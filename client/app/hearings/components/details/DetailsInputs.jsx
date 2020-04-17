import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useContext } from 'react';
import classnames from 'classnames';

import { COLORS } from '../../../constants/AppConstants';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import {
  HearingsFormContext,
  UPDATE_HEARING_DETAILS, UPDATE_TRANSCRIPTION, UPDATE_VIRTUAL_HEARING
} from '../../contexts/HearingsFormContext';
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
  genericRow,
  maxWidthFormInput,
  rowThirds,
  rowThirdsWithFinalSpacer
} from './style';
import COPY from '../../../../COPY';
import Checkbox from '../../../components/Checkbox';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextField from '../../../components/TextField';
import TextareaField from '../../../components/TextareaField';
import TranscriptionDetailsInputs from './TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './TranscriptionProblemInputs';
import TranscriptionRequestInputs from './TranscriptionRequestInputs';
import VirtualHearingLink from '../VirtualHearingLink';

// Displays the emails associated with the virtual hearing.
const EmailSection = (
  { hearing, virtualHearing, isVirtual, wasVirtual, readOnly, dispatch }
) => {
  const showEmailFields = (isVirtual || wasVirtual) && virtualHearing;
  const readOnlyEmails = readOnly || !virtualHearing?.jobCompleted || wasVirtual || hearing.scheduledForIsPast;

  if (!showEmailFields) {
    return null;
  }

  return (
    <div {...rowThirdsWithFinalSpacer}>
      <TextField
        name="Veteran Email for Notifications"
        value={virtualHearing.veteranEmail}
        strongLabel
        className={[classnames('cf-form-textinput', 'cf-inline-field')]}
        readOnly={readOnlyEmails}
        onChange={(veteranEmail) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: { veteranEmail } })}
        inputStyling={maxWidthFormInput}
      />
      <TextField
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
  readOnly: PropTypes.bool
};

// Displays the virtual hearing link and emails.
const VirtualHearingSection = (
  { hearing, virtualHearing, isVirtual, wasVirtual, readOnly, dispatch }
) => {
  if (!isVirtual && !wasVirtual) {
    return null;
  }

  const user = useContext(HearingsUserContext);
  const virtualHearingLabel = virtualHearingRoleForUser(user, hearing) === VIRTUAL_HEARING_HOST ?
    COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL :
    COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;

  return (
    <React.Fragment>
      <div className="cf-help-divider" />
      <h3>
        {wasVirtual && 'Previous '}Virtual Hearing Details
      </h3>
      {isVirtual &&
        <div {...genericRow}>
          <strong>{virtualHearingLabel}</strong>
          <div {...css({ marginTop: '1.5rem' })}>
            {virtualHearing?.jobCompleted &&
              <VirtualHearingLink
                user={user}
                hearing={hearing}
                showFullLink
                isVirtual={isVirtual}
                virtualHearing={virtualHearing}
              />
            }
            {!virtualHearing?.jobCompleted &&
              <span {...css({ color: COLORS.GREY_MEDIUM })}>
                {COPY.VIRTUAL_HEARING_SCHEDULING_IN_PROGRESS}
              </span>
            }
          </div>
        </div>
      }
      <EmailSection
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

const DetailsInputs = (props) => {
  const {
    hearing,
    isLegacy,
    isVirtual,
    openVirtualHearingModal,
    readOnly,
    requestType,
    transcription,
    virtualHearing,
    wasVirtual
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);
  const enableVirtualHearings = userCanScheduleVirtualHearings && requestType !== 'Central';
  const { dispatch } = useContext(HearingsFormContext);

  return (
    <React.Fragment>
      <div {...rowThirds}>
        <JudgeDropdown
          name="judgeDropdown"
          value={hearing?.judgeId}
          readOnly={readOnly}
          onChange={(judgeId) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { judgeId } })}
        />
        <HearingCoordinatorDropdown
          name="hearingCoordinatorDropdown"
          value={hearing?.bvaPoc}
          readOnly={readOnly}
          onChange={(bvaPoc) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { bvaPoc } })}
        />
        <HearingRoomDropdown
          name="hearingRoomDropdown"
          value={hearing?.room}
          readOnly={readOnly}
          onChange={(room) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { room } })}
        />
      </div>
      {enableVirtualHearings &&
        <React.Fragment>
          <div className="cf-help-divider" />
          <div {...flexParent}>
            <HearingTypeDropdown
              virtualHearing={virtualHearing}
              requestType={requestType}
              updateVirtualHearing={(values) => dispatch({ type: UPDATE_VIRTUAL_HEARING, payload: values })}
              openModal={openVirtualHearingModal}
              readOnly={hearing?.scheduledForIsPast || (isVirtual && !virtualHearing?.jobCompleted)}
              styling={columnThird}
            />
            <div {...columnDoubleSpacer} />
          </div>
        </React.Fragment>
      }
      <VirtualHearingSection
        hearing={hearing}
        isVirtual={isVirtual}
        readOnly={readOnly}
        virtualHearing={virtualHearing}
        wasVirtual={wasVirtual}
        dispatch={dispatch}
      />
      {!isLegacy &&
        <React.Fragment>
          <div className="cf-help-divider" />
          <div>
            <strong>Waive 90 Day Evidence Hold</strong>
            <Checkbox
              label="Yes, Waive 90 Day Evidence Hold"
              name="evidenceWindowWaived"
              disabled={readOnly}
              value={hearing?.evidenceWindowWaived || false}
              onChange={(evidenceWindowWaived) => dispatch(
                { type: UPDATE_HEARING_DETAILS, payload: { evidenceWindowWaived } }
              )}
            />
          </div>
        </React.Fragment>
      }
      <div className="cf-help-divider" />
      <TextareaField
        name="Notes"
        strongLabel
        styling={maxWidthFormInput}
        disabled={readOnly}
        value={hearing?.notes || ''}
        onChange={(notes) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { notes } })}
      />
      {!isLegacy &&
        <TranscriptionSection
          hearing={hearing}
          readOnly={readOnly}
          transcription={transcription}
          dispatch={dispatch}
        />
      }
    </React.Fragment>
  );
};

DetailsInputs.propTypes = {
  hearing: PropTypes.shape({
    judgeId: PropTypes.string,
    room: PropTypes.string,
    evidenceWindowWaived: PropTypes.bool,
    notes: PropTypes.string,
    bvaPoc: PropTypes.string,
    scheduledForIsPast: PropTypes.bool
  }),
  readOnly: PropTypes.bool,
  requestType: PropTypes.string,
  isLegacy: PropTypes.bool,
  openVirtualHearingModal: PropTypes.func,
  virtualHearing: PropTypes.shape({
    veteranEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
    status: PropTypes.string,
    jobCompleted: PropTypes.bool
  }),
  enableVirtualHearings: PropTypes.bool,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool,
  transcription: PropTypes.object
};

export default DetailsInputs;
