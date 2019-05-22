import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import { BrowserRouter, Route, Switch } from 'react-router-dom';
import HearingWorksheetContainer from './containers/HearingWorksheetContainer';
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
          title="Hearing Worksheet"
          component={(props) => {

            return browser.name === 'chrome' ?
              <HearingWorksheetContainer
                print
                veteran_law_judge={hearings.veteran_law_judge}
                hearingId={props.match.params.hearingId} /> :
              <UnsupportedBrowserBanner appName="Hearings" />;
          }}
        />
        <Route>
          <div>
            <NavigationBar
              wideApp
              appName="Hearings"
              logoProps={{
                accentColor: LOGO_COLORS.HEARINGS.ACCENT,
                overlapColor: LOGO_COLORS.HEARINGS.OVERLAP
              }}
              userDisplayName={hearings.userDisplayName}
              dropdownUrls={hearings.dropdownUrls}
              applicationUrls={hearings.applicationUrls} >
              <AppFrame wideApp>
                <ScrollToTop />
                <PageRoute exact path="/hearings/:hearingId/worksheet"
                  title="Hearing Worksheet"
                  component={(props) => {

                    return browser.name === 'chrome' ?
                      <HearingWorksheetContainer
                        veteran_law_judge={hearings.veteran_law_judge}
                        hearingId={props.match.params.hearingId} /> :
                      <UnsupportedBrowserBanner appName="Hearings" />;
                  }
                  }
                />
              </AppFrame>
            </NavigationBar>
            <Footer
              wideApp
              appName="Hearings"
              feedbackUrl={hearings.feedbackUrl}
              buildDate={hearings.buildDate} />
          </div>
        </Route>
      </Switch>
    </BrowserRouter>
  </ReduxBase>;
};

export default Hearings;
