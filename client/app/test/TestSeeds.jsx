/* eslint-disable react/prop-types */

import React from 'react';
import NavigationBar from '../components/NavigationBar';
import { BrowserRouter } from 'react-router-dom';
import PageRoute from '../components/PageRoute';
import AppFrame from '../components/AppFrame';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { LOGO_COLORS } from '../constants/AppConstants';
import CaseSearchLink from '../components/CaseSearchLink';
import ApiUtil from '../util/ApiUtil';
import Button from '../components/Button';
import NumberField from '../components/NumberField';
import cx from 'classnames';
import TEST_SEEDS from '../../constants/TEST_SEEDS';
import Alert from 'app/components/Alert';

class TestSeeds extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      reseedingStatus: {
        Aod: false,
        NonAod: false,
        Tasks: false,
        Hearings: false,
        Intake: false,
        Dispatch: false,
        Jobs: false,
        Substitutions: false,
        DecisionIssues: false,
        CavcAmaAppeals: false,
        SanitizedJsonSeeds: false,
        VeteransHealthAdministration: false,
        MTV: false,
        Education: false,
        PriorityDistributions: false,
        TestCaseData: false,
        CaseDistributionAuditLeverEntries: false,
        Notifications: false,
        CavcDashboardData: false,
        VbmsExtClaim: false,
        CasesTiedToJudgesNoLongerWithBoard: false,
        StaticTestCaseData: false,
        StaticDispatchedAppealsTestData: false,
        RemandedAmaAppeals: false,
        RemandedLegacyAppeals: false,
        PopulateCaseflowFromVacols: false
      },
      seedCounts: {},
      seedRunningStatus: false,
      seedRunningMsg: 'Seed running'
    };
  }

  handleInputChange = (type, newValue) => {
    if (newValue === '') {
      this.setState((prevState) => ({
        seedCounts: {
          ...prevState.seedCounts,
          [type]: 1
        }
      }));
    } else {
      this.setState((prevState) => ({
        seedCounts: {
          ...prevState.seedCounts,
          [type]: newValue
        }
      }));
    }
  };

  reseed = (type) => {
    const seedCount = this.state.seedCounts[type] || 1;
    // ToDo

    this.setState({ seedRunning: true, seedRunningMsg: '' });
    this.setState((prevState) => ({
      reseedingStatus: { ...prevState.reseedingStatus, [type]: true }
    }));

    const endpoint = `/seeds/run-demo/${type}/${seedCount}`;

    ApiUtil.post(endpoint).then(() => {
      this.setState({ seedRunning: false });
      this.setState((prevState) => ({
        reseedingStatus: { ...prevState.reseedingStatus, [type]: false }
      }));
    }).
      catch((err) => {
        console.warn(err);
        this.setState({ seedRunning: false });
        this.setState((prevState) => ({
          reseedingStatus: { ...prevState.reseedingStatus, [type]: false }
        }));
      });
  };

  formatSeedName = (name) => {
    return name.split('-').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).
      join(' ');
  };

  render() {
    const Router = this.props.router || BrowserRouter;
    const seedTypes = Object.keys(TEST_SEEDS);

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
          >          <AppFrame>
              <AppSegment filledBackground>
                <div>
                  <PageRoute exact path="/test/seeds" title="Caseflow Seeds" component={() => (
                    <div>
                      <>
                        {this.state.seedRunning && (
                          <Alert
                            title="Seed Running"
                            message={this.state.seedRunningMsg}
                            type="info"
                          />
                        )}
                      </>

                      <h2 id="run_seeds">Run Seed Files</h2>
                      <ul style={{ listStyleType: 'none', padding: 0, margin: 0 }}>
                        {seedTypes.map((type) => (
                          <li key={type}>
                            <div className={cx('lever-right', 'test-seeds-num-field')}>
                              {/* <input
                                type="number"
                                value={this.state.seedCounts[type] || 1}
                                min="1"
                                id={`count-${type}`}
                                onChange={(event) => this.
                                  handleInputChange(type, parseInt(event.target.value, 10) || 1)}
                              /> */}
                              <NumberField
                                name=""
                                isInteger
                                value={this.state.seedCounts[type] || '1'}
                                onChange={(newValue) => this.handleInputChange(type, newValue)}
                              />
                            </div>
                            <div className="cf-btn-link test-seed-button-style">
                              <Button
                                onClick={() => this.reseed(type)}
                                name={`Run Demo ${this.formatSeedName(type)}`}
                                loading={this.state.reseedingStatus[type]}
                                loadingText={`Reseeding ${this.formatSeedName(type)}`}
                              />
                            </div>
                            <>
                              {this.state.reseedingStatus[type] && (
                                <div className="test-seed-alert-message">
                                  <span>{this.formatSeedName(type)} in progress</span>
                                </div>
                              )}
                            </>
                          </li>
                        ))}
                      </ul>
                      <hr />
                    </div>
                  )} />
                </div>
              </AppSegment>
            </AppFrame>
          </NavigationBar>
        </div>
      </Router>
    );
  }
}

export default TestSeeds;
