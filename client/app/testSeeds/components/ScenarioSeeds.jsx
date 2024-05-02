import React from 'react';
import COPY from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import Button from 'app/components/Button';
import cx from 'classnames';
import TEST_SEEDS from '../../../constants/TEST_SEEDS';

class ScenarioSeeds extends React.Component {
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
  }

  handleChange= (event, type) => {
    this.seedCounts[type] = event.target.value;
  }

  formatSeedName = (name) => {
    return name.split('-').map((word) => word.charAt(0).toUpperCase() + word.slice(1)).
      join(' ');
  };

  reseed = (type) => {
    const seedCount = parseInt(this.seedCounts[type], 10) || 1;

    this.setState({ seedRunning: true, seedRunningMsg: '' });
    this.setState((prevState) => ({
      reseedingStatus: { ...prevState.reseedingStatus, [type]: true }
    }));

    // const endpoint = `/seeds/run-demo/${type}?seed_count=${seedCount}`;
    const endpoint = `/seeds/run-demo?seed_type=${type}&seed_count=${seedCount}`;

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

  render() {
    const seedTypes = Object.keys(TEST_SEEDS);

    return (
      <div>
        <>
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
        </>
      </div>
    );
  }
}

// ScenarioSeeds.propTypes = {

// }

export default ScenarioSeeds;
