import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route } from 'react-router-dom';

import ClaimsForReviewContainer from './ClaimsForReviewContainer';
import { manageIntakeReducers, mapDataToInitialState } from './reducers';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';

const ManageIntake = ({
  userDisplayName,
  dropdownUrls,
  feedbackUrl,
  buildDate
}) => {

  const initialState = mapDataToInitialState();

  return <ReduxBase initialState={initialState} reducer={manageIntakeReducers}>
    <div>
      <BrowserRouter basename="/intake/manage">
        <div>
          <NavigationBar
            appName="Manage Intakes"
            logoProps={{
              accentColor: LOGO_COLORS.INTAKE.ACCENT,
              overlapColor: LOGO_COLORS.INTAKE.OVERLAP
            }}
            defaultUrl="/intake/manage"
            userDisplayName={userDisplayName}
            dropdownUrls={dropdownUrls}>
            <div className="cf-wide-app">
              <div className="usa-grid">
                <Route exact path="/"
                  component={() => <ClaimsForReviewContainer />}
                />

              </div>
            </div>
          </NavigationBar>
          <Footer
            appName="Manage Intakes"
            feedbackUrl={feedbackUrl}
            buildDate={buildDate} />
        </div>
      </BrowserRouter>
    </div>
  </ReduxBase>;
};

export default ManageIntake;
