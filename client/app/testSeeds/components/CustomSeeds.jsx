import React from 'react';
import COPY from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import Button from 'app/components/Button';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import cx from 'classnames';
import CUSTOM_SEEDS from '../../../constants/CUSTOM_SEEDS';

class CustomSeeds extends React.PureComponent {
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
    this.seedByType = {};
  }

  onChangeCaseType = (type, inputKey, value) => {
    if (typeof this.seedByType[type] !== 'object') {
      this.seedByType[type] = {};
    }
    this.seedByType[type][inputKey] = value;
  }

  reseedByCaseType = (type) => {
    const caseType = this.seedByType[type];

    caseType.seed_type = type;

    this.setState({ seedRunning: true, seedRunningMsg: '' });
    this.setState((prevState) => ({
      reseedingStatus: { ...prevState.reseedingStatus, [type]: true }
    }));

    // ApiUtil.post(`/seeds/run-demo/${type}`, { data: caseType }).then(() => {
    ApiUtil.post('/seeds/run-demo', { data: caseType }).then(() => {
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
    const seedTypes = Object.keys(CUSTOM_SEEDS);

    return (
      <div>
        <>
          <h2 id="run_custom_seeds">{COPY.TEST_SEEDS_CUSTOM_SEEDS}</h2>
          <table className="seed-table-style" >
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
                    {CUSTOM_SEEDS[type]}
                  </td>
                  <td>
                    <div className={cx('lever-right', 'test-seeds-num-field')}>
                      <NumberField
                        ariaLabelText={`seed-count-${type}`}
                        useAriaLabel
                        inputID={`seed-count-${type}`}
                        onChange={(value) => {
                          this.onChangeCaseType(type, 'seed_count', value);
                        }}
                      />
                    </div>
                  </td>
                  <td>
                    <div className={cx('lever-right', 'test-seeds-num-field')}>
                      <NumberField
                        ariaLabelText={`days-ago-${type}`}
                        useAriaLabel
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
                        useAriaLabel
                        inputID={`css-id-${type}`}
                        onChange={(value) => {
                          this.onChangeCaseType(type, 'judge_css_id', value);
                        }}
                      />
                    </div>
                  </td>
                  <td>
                    <div className="cf-btn-link lever-right test-seed-button-style">
                      <Button
                        onClick={() => this.reseedByCaseType(type)}
                        id={`btn-${type}`}
                        name="Create"
                        loading={this.state.reseedingStatus[type]}
                        loadingText={`Reseeding ${CUSTOM_SEEDS[type]}`}
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <hr />
        </>
      </div>
    );
  }
}

export default CustomSeeds;
