import PropTypes from 'prop-types';
import React, { useContext } from 'react';

import { HearingsUserContext } from '../HearingsUserContext';
import DetailsInputs from './details/DetailsInputs';
import TranscriptionDetailsInputs from './details/TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './details/TranscriptionProblemInputs';
import TranscriptionRequestInputs from './details/TranscriptionRequestInputs';

const DetailsSections = (props) => {
  const {
    transcription,
    hearing,
    disabled,
    updateHearing,
    updateTranscription,
    updateVirtualHearing,
    isLegacy,
    virtualHearing,
    requestType,
    openVirtualHearingModal,
    isVirtual,
    wasVirtual
  } = props;
  const { userCanScheduleVirtualHearings } = useContext(HearingsUserContext);

  return (
    <>
      <DetailsInputs
        readOnly={disabled}
        requestType={requestType}
        isLegacy={isLegacy}
        hearing={hearing}
        scheduledForIsPast={hearing.scheduledForIsPast}
        update={updateHearing}
        enableVirtualHearings={userCanScheduleVirtualHearings && requestType !== 'Central'}
        virtualHearing={virtualHearing}
        updateVirtualHearing={updateVirtualHearing}
        openVirtualHearingModal={openVirtualHearingModal}
        isVirtual={isVirtual}
        wasVirtual={wasVirtual} />
      <div className="cf-help-divider" />
      {!isLegacy &&
        <div>
          <h2>Transcription Details</h2>
          <TranscriptionDetailsInputs
            transcription={transcription}
            update={updateTranscription}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <h2>Transcription Problem</h2>
          <TranscriptionProblemInputs
            transcription={transcription}
            update={updateTranscription}
            readOnly={disabled} />
          <div className="cf-help-divider" />

          <h2>Transcription Request</h2>
          <TranscriptionRequestInputs
            hearing={hearing}
            update={updateHearing}
            readOnly={disabled} />
          <div className="cf-help-divider" />
        </div>
      }
    </>
  );
}

DetailsSections.propTypes = {
  transcription: PropTypes.object,
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  disabled: PropTypes.bool,
  updateHearing: PropTypes.func,
  updateTranscription: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  isLegacy: PropTypes.bool,
  requestType: PropTypes.string,
  submit: PropTypes.func,
  openVirtualHearingModal: PropTypes.func,
  isVirtual: PropTypes.bool,
  wasVirtual: PropTypes.bool
};

// These props are set through Redux
// set default values for time between mount
// and redux state being set
DetailsSections.defaultProps = {
  hearing: {},
  transcription: {}
};

export default DetailsSections;
