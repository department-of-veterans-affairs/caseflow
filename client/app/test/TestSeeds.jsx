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
import cx from 'classnames';
import TEST_SEEDS from '../../constants/TEST_SEEDS';
import Alert from 'app/components/Alert';
import COPY from '../../COPY';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';

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
      seedRunningStatus: false,
      seedRunningMsg: 'Seeds running'
    };
    this.seedCounts = {};
    this.seedByType = {};
  }

  handleChange= (event, type) => {
    this.seedCounts[type] = event.target.value;
  }

  onChangeCountField = (type, value) =>  {
    this.seedCounts[type] = value;
  };

  onChangeCaseType = (type, inputKey, value) => {
    if(typeof this.seedByType[type] !== 'object'){
      this.seedByType[type] = {};
    }
    this.seedByType[type][inputKey] = [value];
  }

  reseed = (type) => {
    const seedCount = parseInt(this.seedCounts[type], 10) || 1;
    const daysAge = parseInt(this.seedCounts["days-ago-"+type], 10);
    const cssId = this.seedCounts["css-id-"+type];

    this.setState({ seedRunning: true, seedRunningMsg: '' });
    this.setState((prevState) => ({
      reseedingStatus: { ...prevState.reseedingStatus, [type]: true }
    }));

    // const endpoint = `/seeds/run-demo/${type}/${seedCount}`;
    const endpoint = `/seeds/run-demo/${type}/${seedCount}?days_age=${daysAge}&css_id=${cssId}`;

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

  reseedByCaseType = (type) => {
    const caseType = this.seedByType[type];

    this.setState({ seedRunning: true, seedRunningMsg: '' });
    this.setState((prevState) => ({
      reseedingStatus: { ...prevState.reseedingStatus, [type]: true }
    }));

    ApiUtil.post(`/seeds/individual_case_type`, { data: caseType }).then(() => {
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
                      <table className='seed-table-style' >
                        <thead>
                          <tr>
                            <th className={cx('table-header-styling')}>
                              Case Type
                            </th>
                            <th className={cx('table-header-styling')}>
                              Number of cases to create
                            </th>
                            <th className={cx('table-header-styling')}>
                              Days Ago
                            </th>
                            <th className={cx('table-header-styling')}>
                              Judge CSS_ID (optional)
                            </th>
                            <th className={cx('table-header-styling')}>
                            </th>
                          </tr>
                        </thead>
                        <tbody>
                          {seedTypes.map((type) => (
                            <tr>
                              <td>
                                {type}
                              </td>
                              <td>
                                <div className={cx('lever-right', 'test-seeds-num-field')}>
                                  <NumberField
                                    ariaLabelText={`case-count-${type}`}
                                    inputID={`case-count-${type}`}
                                    onChange={(value) => {
                                      this.onChangeCaseType(type, 'case_count', value);
                                    }}
                                  />
                                </div>
                              </td>
                              <td>
                                <div className={cx('lever-right', 'test-seeds-num-field')}>
                                  <NumberField
                                    ariaLabelText={`days-ago-${type}`}
                                    inputID={`days-ago-${type}`}
                                    onChange={(value) => {
                                      this.onChangeCaseType(type, 'days_ago', value);
                                    }}
                                  />
                                </div>
                              </td>
                              <td>
                                <div className={cx('lever-right', 'test-seeds-cssid-field')}>
                                  <TextField
                                    ariaLabelText={`css-id-${type}`}
                                    inputID={`css-id-${type}`}
                                    onChange={(value) => {
                                      this.onChangeCaseType(type, 'css_id', value);
                                    }}
                                  />
                                </div>
                              </td>
                              <td>
                                <div className="cf-btn-link lever-right test-seed-button-style">
                                  <Button
                                    onClick={() => this.reseedByCaseType(type)}
                                    name='Create'
                                    loading={this.state.reseedingStatus[type]}
                                    loadingText={`Reseeding ${this.formatSeedName(type)}`}
                                  />
                                </div>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                      <hr />
                      <h2 id="run_seeds">{COPY.TEST_SEEDS_RUN_SEEDS}</h2>
                      <ul style={{ listStyleType: 'none', padding: 0, margin: 0 }}>
                        {seedTypes.map((type) => (
                          <li key={type}>
                            <div className={cx('lever-right', 'test-seeds-num-field')}>
                              <input
                                aria-label={`count-${type}`}
                                type="text"
                                id={`count-${type}`}
                                onChange={(event) => this.handleChange(event, type)}
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
                                  <span>{this.formatSeedName(type)} {COPY.TEST_SEEDS_ALERT_MESSAGE}</span>
                                </div>
                              )}
                            </>
                          </li>
                        ))}
                      </ul>
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
