import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';

import bootstrapRedux from '../../establishClaim/reducers/bootstrap';
import ReduxBase from '../../components/ReduxBase';
import EstablishClaimContainer from './EstablishClaimContainer';

export const EstablishClaimPage = (props) => {
  const { initialState, reducer } = bootstrapRedux(props);

  return (
    <ReduxBase initialState={initialState} reducer={reducer}>
      <BrowserRouter>
        <EstablishClaimContainer {...props} />
      </BrowserRouter>
    </ReduxBase>
  );
};

export default EstablishClaimPage;

EstablishClaimPage.propTypes = {
  page: PropTypes.string.isRequired,
  task: PropTypes.object,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};
