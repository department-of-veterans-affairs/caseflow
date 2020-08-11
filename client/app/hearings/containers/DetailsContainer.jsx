import PropTypes from 'prop-types';
import React, { useContext, useState } from 'react';

import { HearingsFormContextProvider } from '../contexts/HearingsFormContext';
import { HearingsUserContext } from '../contexts/HearingsUserContext';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import HearingDetails from '../components/Details';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

export const HearingDetailsContainer = ({ hearingId, history }) => {
  const [hearing, setHearing] = useState(null);
  const { userInHearingOrTranscriptionOrganization } = useContext(HearingsUserContext);

  const getHearing = () => (
    ApiUtil.
      get(`/hearings/${hearingId}`).
      then((resp) => {
        // This represents the initial hearing that is setup in the HearingsFormContext.
        // Afterwards, the initial hearing is managed by the HearingDetails child.
        setHearing(ApiUtil.convertToCamelCase(resp.body.data));
      })
  );

  const saveHearing = (data) => {
    return ApiUtil.
      patch(`/hearings/${hearing.externalId}`, { data: ApiUtil.convertToSnakeCase(data) });
  };

  return (
    <LoadingDataDisplay
      createLoadPromise={getHearing}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
        message: 'Loading the hearing details...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the details.'
      }}
    >
      <HearingsFormContextProvider hearing={hearing}>
        <HearingDetails
          disabled={!userInHearingOrTranscriptionOrganization}
          saveHearing={saveHearing}
          goBack={history.goBack}
        />
      </HearingsFormContextProvider>
    </LoadingDataDisplay>
  );
};

HearingDetailsContainer.propTypes = {
  hearingId: PropTypes.string.isRequired,
  history: PropTypes.object
};
