import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route } from 'react-router-dom';

import FlaggedForReviewContainer from './FlaggedForReviewContainer';
import { intakeManagerReducers, mapDataToInitialState } from './reducers';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../constants/AppConstants';

const IntakeManager = ({
  userDisplayName,
  dropdownUrls,
  feedbackUrl,
  buildDate
}) => {

  const initialState = mapDataToInitialState();

  return <ReduxBase initialState={initialState} reducer={intakeManagerReducers}>
    <div>
      <BrowserRouter basename="/intake/manager">
        <div>
          <NavigationBar
            appName="Intake Manager"
            logoProps={{
              accentColor: LOGO_COLORS.INTAKE.ACCENT,
              overlapColor: LOGO_COLORS.INTAKE.OVERLAP
            }}
            defaultUrl="/"
            userDisplayName={userDisplayName}
            dropdownUrls={dropdownUrls}>
            <div className="cf-wide-app">
              <div className="usa-grid">
                <Route exact path="/"
                  component={() => <FlaggedForReviewContainer />}
                />

              </div>
            </div>
          </NavigationBar>
          <Footer
            appName="Intake Manager"
            feedbackUrl={feedbackUrl}
            buildDate={buildDate} />
        </div>
      </BrowserRouter>
    </div>
  </ReduxBase>;
};

export default IntakeManager;
