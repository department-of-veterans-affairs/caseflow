import PropTypes from 'prop-types';
import React, { useState } from 'react';
import { LOGO_COLORS } from '../../constants/AppConstants';
import TranscriptionSettings from '../components/transcriptionProcessing/TranscriptionSettings';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';

export const TranscriptionSettingsContainer = () => {
  const [contractors, setContractors] = useState([]);
  const getContractors = () =>
    ApiUtil.get('/hearings/find_by_contractor').then((response) => {
      setContractors(response.body.transcription_contractors);

      return response.body.transcription_contractors;
    });

  return (
    <LoadingDataDisplay
      createLoadPromise={getContractors}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: 'Loading the transcription settings...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the transcription settings.'
      }}
    >
      <TranscriptionSettings contractors={contractors} />
    </LoadingDataDisplay>
  );
};

TranscriptionSettingsContainer.propTypes = {
  history: PropTypes.object
};
