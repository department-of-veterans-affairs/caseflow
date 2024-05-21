import React, { useState } from 'react';
import COPY from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import Button from 'app/components/Button';
import cx from 'classnames';
import TEST_SEEDS from '../../../constants/TEST_SEEDS';

const ScenarioSeeds = () => {
  const [reseedingStatus, setReseedingStatus] = useState({
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
  });
  const [seedRunningStatus, setSeedRunningStatus] = useState(false);
  const [seedRunningMsg, setSeedRunningMsg] = useState('Seeds running');
  const [seedCounts, setSeedCounts] = useState({});

  const handleChange = (event, type) => {
    setSeedCounts(prevState => ({
      ...prevState,
      [type]: event.target.value
    }));
  };

  const formatSeedName = (name) => {
    return name.split('-').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ');
  };

  const reseed = (type) => {
    const seedCount = parseInt(seedCounts[type], 10) || 1;

    setSeedRunningStatus(true);
    setSeedRunningMsg('');
    setReseedingStatus(prevState => ({
      ...prevState,
      [type]: true
    }));

    const endpoint = `/seeds/run-demo?seed_type=${type}&seed_count=${seedCount}`;

    ApiUtil.post(endpoint)
      .then(() => {
        setSeedRunningStatus(false);
        setReseedingStatus(prevState => ({
          ...prevState,
          [type]: false
        }));
      })
      .catch(err => {
        console.warn(err);
        setSeedRunningStatus(false);
        setReseedingStatus(prevState => ({
          ...prevState,
          [type]: false
        }));
      });
  };

  const seedTypes = Object.keys(TEST_SEEDS);

  return (
    <div>
      <>
        <h2 id="run_seeds">{COPY.TEST_SEEDS_RUN_SEEDS}</h2>
        <ul style={{ listStyleType: 'none', padding: 0, margin: 0 }}>
          {seedTypes.map(type => (
            <li key={type}>
              <div className={cx('lever-right', 'test-seeds-num-field')}>
                <input
                  aria-label={`count-${type}`}
                  type="text"
                  id={`count-${type}`}
                  onChange={event => handleChange(event, type)}
                />
              </div>
              <div className="cf-btn-link test-seed-button-style">
                <Button
                  onClick={() => reseed(type)}
                  name={`Run Demo ${formatSeedName(type)}`}
                  loading={reseedingStatus[type]}
                  loadingText={`Reseeding ${formatSeedName(type)}`}
                />
              </div>
              <>
                {reseedingStatus[type] && (
                  <div className="test-seed-alert-message">
                    <span>{formatSeedName(type)} {COPY.TEST_SEEDS_ALERT_MESSAGE}</span>
                  </div>
                )}
              </>
            </li>
          ))}
        </ul>
      </>
    </div>
  );
};

export default ScenarioSeeds;
