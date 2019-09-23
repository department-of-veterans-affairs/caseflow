import React from 'react';
import PropTypes from 'prop-types';
import ReduxBase from '../components/ReduxBase';

import { BrowserRouter, Route } from 'react-router-dom';

import StuckTasksContainer from './StuckTasksContainer';
import { establishClaimAdminReducers, mapDataToInitialState } from './reducers';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';

const EstablishClaimAdmin = ({ userDisplayName, dropdownUrls, feedbackUrl, buildDate }) => {
  const initialState = mapDataToInitialState();

  return (
    <ReduxBase initialState={initialState} reducer={establishClaimAdminReducers}>
      <div>
        <BrowserRouter basename="/dispatch/admin">
          <div>
            <NavigationBar
              appName="Establish Claim Admin"
              logoProps={{
                accentColor: LOGO_COLORS.DISPATCH.ACCENT,
                overlapColor: LOGO_COLORS.DISPATCH.OVERLAP
              }}
              defaultUrl="/dispatch/admin"
              userDisplayName={userDisplayName}
              dropdownUrls={dropdownUrls}
              wideApp
            >
              <div className="cf-wide-app">
                <div className="usa-grid">
                  <Route exact path="/" component={() => <StuckTasksContainer />} />
                </div>
              </div>
            </NavigationBar>
            <Footer appName="Establish Claim Admin" feedbackUrl={feedbackUrl} buildDate={buildDate} />
          </div>
        </BrowserRouter>
      </div>
    </ReduxBase>
  );
};

EstablishClaimAdmin.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};

export default EstablishClaimAdmin;
