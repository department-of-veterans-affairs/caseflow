/* eslint-disable react/prop-types */

import React from 'react';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import CaseSearchLink from '../components/CaseSearchLink';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';

class DemoSeeds extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      isReseedingAod: false,
      isReseedingNonAod: false,
    };
  }

  reseedAod = () => {
    this.setState({ isReseedingAod: true });
    ApiUtil.post('/run-demo-aod-seeds').then(() => {
      this.setState({
        isReseedingAod: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingAod: false,
      });
    });
  };

  reseedNonAod = () => {
    this.setState({ isReseedingNonAod: true });
    ApiUtil.post('/run-demo-non-aod-seeds').then(() => {
      this.setState({
        isReseedingNonAod: false,
      });
    }, (err) => {
      console.warn(err);
      this.setState({
        isReseedingNonAod: false,
      });
    });
  };

  render() {
    const Router = this.props.router || BrowserRouter;
    // const appName = 'Case Distribution';
    // const tablestyle = {
    //   display: 'block',
    //   overflowX: 'scroll'
    // };

    return (
      <Router {...this.props.routerTestProps}>
        <div>
        <NavigationBar
            wideApp
            defaultUrl={
              this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ?
                '/search' :
                '/queue'
            }
            userDisplayName={this.props.userDisplayName}
            dropdownUrls={this.props.dropdownUrls}
            applicationUrls={this.props.applicationUrls}
            logoProps={{
              overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
              accentColor: LOGO_COLORS.QUEUE.ACCENT,
            }}
            rightNavElement={<CaseSearchLink />}
            appName="Caseflow Admin"
          >
            <AppFrame>
              <AppSegment filledBackground>
                <div>
                <PageRoute
                    exact
                    path="/test/seeds"
                    title="Caseflow Seeds"
                    component={() => {
                      return (
                        <div>
                          Hello seeds too!
                        </div>

                      );
                    }}
                  />
                </div>
              </AppSegment>
            </AppFrame>
        </NavigationBar>
        </div>
      </Router>
    );

  }
}

export default DemoSeeds;
