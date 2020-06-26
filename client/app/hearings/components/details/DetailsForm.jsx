import PropTypes from 'prop-types';
import React, { useContext } from 'react';

import { ContentSection } from '../../../components/ContentSection';
import { EmailNotificationHistory } from './EmailNotificationHistory';
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
    hearing,
    updateHearing,
    isLegacy,
    isVirtual,
    openVirtualHearingModal,
    readOnly,
    requestType,
    wasVirtual,
    errors,
    updateVirtualHearing,
    convertHearing
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);
  const enableVirtualHearings = userCanScheduleVirtualHearings;

  console.log('JUDGE: ', hearing.judgeId);

  return (
    <React.Fragment>
      <ContentSection header="Hearing Details">
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
        <div {...rowThirds}>
          {enableVirtualHearings && (
            <HearingTypeDropdown
              convertHearing={convertHearing}
              virtualHearing={hearing.virtualHearing}
              requestType={requestType}
              updateVirtualHearing={updateVirtualHearing}
              openModal={openVirtualHearingModal}
              readOnly={
                hearing?.scheduledForIsPast ||
                ((isVirtual || wasVirtual) && !hearing.virtualHearing?.jobCompleted)
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
                    updateHearing({ evidenceWindowWaived })
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
            onChange={(notes) => updateHearing({ notes })}
          />
        </div>
      </ContentSection>

      <VirtualHearingForm
        errors={errors}
        hearing={hearing}
        isVirtual={isVirtual}
        readOnly={readOnly}
        virtualHearing={hearing.virtualHearing}
        wasVirtual={wasVirtual}
        updateHearing={updateHearing}
      />

      {hearing?.emailEvents.length > 0 && (
        <EmailNotificationHistory rows={hearing?.emailEvents} />
      )}

      {!isLegacy && (
        <TranscriptionFormSection
          hearing={hearing}
          readOnly={readOnly}
          transcription={hearing.transcription}
          updateHearing={updateHearing}
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
