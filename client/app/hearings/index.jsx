import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';

import { BrowserRouter, Route, Switch } from 'react-router-dom';
import DocketsContainer from './containers/DocketsContainer';
import DailyDocketContainer from './containers/DailyDocketContainer';
import HearingWorksheetContainer from './containers//HearingWorksheetContainer';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';
import ScrollToTop from '../components/ScrollToTop';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import PageRoute from '../components/PageRoute';
import { LOGO_COLORS } from '../constants/AppConstants';
import UnsupportedBrowserBanner from '../components/UnsupportedBrowserBanner';
import { detect } from 'detect-browser';

const Hearings = ({ hearings }) => {
  const browser = detect();

  return <ReduxBase reducer={hearingsReducers} initialState={mapDataToInitialState(hearings)}>
    <BrowserRouter>
      <Switch>
        <PageRoute exact path="/hearings/:hearingId/worksheet/print"
          breadcrumb="Daily Docket > Hearing Worksheet"
          title="Hearing Worksheet"
          component={(props) => {

            return browser.name === 'chrome' ?
              <HearingWorksheetContainer
                print
                veteran_law_judge={hearings.veteran_law_judge}
                hearingId={props.match.params.hearingId} /> :
              <UnsupportedBrowserBanner appName="Hearing Prep" />;
          }}
        />
        <Route>
          <div>
            <NavigationBar
              wideApp
              appName="Hearing Prep"
              logoProps={{
                accentColor: LOGO_COLORS.HEARINGS.ACCENT,
                overlapColor: LOGO_COLORS.HEARINGS.OVERLAP
              }}
              defaultUrl="/hearings/dockets"
              userDisplayName={hearings.userDisplayName}
              dropdownUrls={hearings.dropdownUrls}
              applicationUrls={hearings.applicationUrls} >
              <AppFrame wideApp>
                <ScrollToTop />
                <PageRoute exact path="/hearings/dockets"
                  title="Your Hearing Days"
                  component={() => {

                    return browser.name === 'chrome' ?
                      <DocketsContainer veteranLawJudge={hearings.veteran_law_judge} /> :
                      <UnsupportedBrowserBanner appName="Hearing Prep" />;
                  }}
                />

                <PageRoute exact path="/hearings/dockets/:date"
                  breadcrumb="Daily Docket"
                  title="Daily Docket"
                  component={(props) => {

                    return browser.name === 'chrome' ?
                      <DailyDocketContainer
                        veteran_law_judge={hearings.veteran_law_judge}
                        date={props.match.params.date} /> :
                      <UnsupportedBrowserBanner appName="Hearing Prep" />;
                  }}
                />

                <PageRoute exact path="/hearings/:hearingId/worksheet"
                  breadcrumb="Daily Docket > Hearing Worksheet"
                  title="Hearing Worksheet"
                  component={(props) => {

                    return browser.name === 'chrome' ?
                      <HearingWorksheetContainer
                        veteran_law_judge={hearings.veteran_law_judge}
                        hearingId={props.match.params.hearingId} /> :
                      <UnsupportedBrowserBanner appName="Hearing Prep" />;
                  }
                  }
                />

              </AppFrame>
            </NavigationBar>
            <Footer
              wideApp
              appName="Hearing Prep"
              feedbackUrl={hearings.feedbackUrl}
              buildDate={hearings.buildDate} />
          </div>
        </Route>
      </Switch>
    </BrowserRouter>
  </ReduxBase>;
};

export default Hearings;
