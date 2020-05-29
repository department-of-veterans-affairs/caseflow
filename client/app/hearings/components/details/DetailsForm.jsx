import PropTypes from 'prop-types';
import React, { useContext } from 'react';

import { ContentSection } from '../../../components/ContentSection';
import { EmailNotificationHistory } from './EmailNotificationHistory';
import {
  HearingsFormContext,
  UPDATE_HEARING_DETAILS
} from '../../contexts/HearingsFormContext';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown
} from '../../../components/DataDropdowns/index';
import { TranscriptionFormSection } from './TranscriptionFormSection';
import { VirtualHearingForm } from './VirtualHearingForm';
import { columnThird, maxWidthFormInput, rowThirds } from './style';
import Checkbox from '../../../components/Checkbox';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextareaField from '../../../components/TextareaField';

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
      <ContentSection header="Hearing Details">
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
        <div {...rowThirds}>
          {enableVirtualHearings && (
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
          )}
          {!isLegacy && (
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
          )}
          <div></div>
        </div>
        <div>
          <TextareaField
            name="Notes"
            strongLabel
            styling={maxWidthFormInput}
            disabled={readOnly}
            value={hearingDetailsForm?.notes || ''}
            onChange={(notes) => dispatch({ type: UPDATE_HEARING_DETAILS, payload: { notes } })}
          />
        </div>
      </ContentSection>

      <VirtualHearingForm
        errors={errors}
        hearing={hearingDetailsForm}
        isVirtual={isVirtual}
        readOnly={readOnly}
        virtualHearing={virtualHearingForm}
        wasVirtual={wasVirtual}
        dispatch={dispatch}
      />

      {hearingDetailsForm?.emailEvents.length > 0 &&
        <EmailNotificationHistory rows={hearingDetailsForm?.emailEvents} />
      }

      {!isLegacy &&
        <TranscriptionFormSection
          hearing={hearingDetailsForm}
          readOnly={readOnly}
          transcription={transcriptionDetailsForm}
          dispatch={dispatch}
        />
      }
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
