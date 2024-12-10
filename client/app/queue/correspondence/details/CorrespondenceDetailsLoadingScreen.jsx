import React from 'react';
import LoadingDataDisplay from '../../../components/LoadingDataDisplay';
import { fetchCorrespondenceDetailsInitialPayload } from '../correspondenceDetailsReducer/correspondenceDetailsActions';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';

const CorrespondenceDetailsLoadingScreen = (props) => {
  const correspondenceUUID = props.correspondence_uuid;
  const dispatch = useDispatch();

  return (
    <LoadingDataDisplay
      createLoadPromise={() => dispatch(fetchCorrespondenceDetailsInitialPayload(correspondenceUUID))}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading the hearing details...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the details.'
      }}
    >
      {props.children}
    </LoadingDataDisplay>
  );
};

CorrespondenceDetailsLoadingScreen.propTypes = {
  children: PropTypes.node,
  fetchVeteranInformation: PropTypes.func,
  correspondence_uuid: PropTypes.string
};

export default CorrespondenceDetailsLoadingScreen;
