import React from 'react';
import ReduxBase from '../util/ReduxBase';

import { BrowserRouter, Route } from 'react-router-dom';

import StuckTasksContainer from './StuckTasksContainer';
import { establishClaimAdminReducers, mapDataToInitialState } from './reducers';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';

const EstablishClaimAdmin = ({
  userDisplayName,
  dropdownUrls,
  feedbackUrl,
  buildDate
}) => {

  const initialState = mapDataToInitialState();

  return <ReduxBase initialState={initialState} reducer={establishClaimAdminReducers}>
    <div>
      <BrowserRouter basename="/dispatch/admin">
        <div>
          <NavigationBar
            appName="Establish Claim Admin"
            defaultUrl="/dispatch/admin"
            userDisplayName={userDisplayName}
            dropdownUrls={dropdownUrls}>
            <div className="cf-wide-app">
              <div className="usa-grid">
                <Route exact path="/"
                  component={() => <StuckTasksContainer />}
                />

              </div>
            </div>
          </NavigationBar>
          <Footer
            appName="Establish Claim Admin"
            feedbackUrl={feedbackUrl}
            buildDate={buildDate} />
        </div>
      </BrowserRouter>
    </div>
  </ReduxBase>;
};

export default EstablishClaimAdmin;
