import PropTypes from 'prop-types';
import React, { useContext } from 'react';

import { ContentSection } from '../../../components/ContentSection';
import { EmailNotificationHistory } from './EmailNotificationHistory';
import { HearingsUserContext } from '../../contexts/HearingsUserContext';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown,
} from '../../../components/DataDropdowns/index';
import { TranscriptionFormSection } from './TranscriptionFormSection';
import { VirtualHearingForm } from './VirtualHearingForm';
import { columnThird, maxWidthFormInput, rowThirds } from './style';
import Checkbox from '../../../components/Checkbox';
import HearingTypeDropdown from './HearingTypeDropdown';
import TextareaField from '../../../components/TextareaField';

const DetailsForm = (props) => {
  const {
    hearing,
    update,
    isLegacy,
    openVirtualHearingModal,
    readOnly,
    requestType,
    errors,
    convertHearing,
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);
  const { userCanScheduleVirtualHearingsForCentral } = useContext(HearingsUserContext);
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
      {(enableVirtualHearings || userCanScheduleVirtualHearingsForCentral) && (
        <React.Fragment>
          <div className="cf-help-divider" />
          <div {...flexParent}>
            <HearingTypeDropdown
              convertHearing={convertHearing}
              virtualHearing={hearing?.virtualHearing}
              requestType={requestType}
              update={update}
              openModal={openVirtualHearingModal}
              readOnly={
                hearing?.scheduledForIsPast ||
                ((hearing?.isVirtual || hearing?.wasVirtual) &&
                  !hearing?.virtualHearing?.jobCompleted)
              }
              styling={columnThird}
            />
          )}
          <div>
            {!isLegacy && (
              <React.Fragment>
                <strong>Waive 90 Day Evidence Hold</strong>
                <Checkbox
                  label="Yes, Waive 90 Day Evidence Hold"
                  name="evidenceWindowWaived"
                  disabled={readOnly}
                  value={hearing?.evidenceWindowWaived || false}
                  onChange={(evidenceWindowWaived) =>
                    update('hearing', { evidenceWindowWaived })
                  }
                />
              </React.Fragment>
            )}
          </div>
          <div />
        </div>
        <div>
          <TextareaField
            name="Notes"
            strongLabel
            styling={maxWidthFormInput}
            disabled={readOnly}
            value={hearing?.notes || ''}
            onChange={(notes) => update('hearing', { notes })}
            maxlength={1000}
          />
        </div>
      </ContentSection>

      <VirtualHearingForm
        errors={errors}
        hearing={hearing}
        readOnly={readOnly}
        virtualHearing={hearing?.virtualHearing}
        update={update}
      />

      {hearing?.emailEvents?.length > 0 && (
        <EmailNotificationHistory rows={hearing?.emailEvents} />
      )}

      {!isLegacy && (
        <TranscriptionFormSection
          hearing={hearing}
          readOnly={readOnly}
          transcription={hearing.transcription}
          update={update}
        />
      )}
    </React.Fragment>
  );
};

DetailsForm.propTypes = {
  errors: PropTypes.shape({
    appellantEmail: PropTypes.string,
    representativeEmail: PropTypes.string,
  }),
  hearing: PropTypes.shape({
    virtualHearing: PropTypes.object,
    transcription: PropTypes.object,
    wasVirtual: PropTypes.bool,
    isVirtual: PropTypes.bool,
  }),
  isLegacy: PropTypes.bool,
  openVirtualHearingModal: PropTypes.func,
  readOnly: PropTypes.bool,
  requestType: PropTypes.string,
  update: PropTypes.func,
  convertHearing: PropTypes.func,
};

export default DetailsForm;
