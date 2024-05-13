import PropTypes from 'prop-types';
import React, { useState } from 'react';

import { LOGO_COLORS } from '../../constants/AppConstants';
import TranscriptionSettings from '../components/transcriptionProcessing/TranscriptionSettings';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

export const TranscriptionSettingsContainer = () => {
  const [setContractors] = useState(null);

  const getContractors = () => (
    setContractors([{ test: 'test' }])
  );

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
      <TranscriptionSettings />
    </LoadingDataDisplay>
  );
};

TranscriptionSettingsContainer.propTypes = {
  history: PropTypes.object
};
