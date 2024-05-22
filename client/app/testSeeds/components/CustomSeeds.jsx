import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import COPY from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import Button from 'app/components/Button';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import cx from 'classnames';
import CUSTOM_SEEDS from '../../../constants/CUSTOM_SEEDS';
import { PlusIcon } from 'app/components/icons/PlusIcon';
import { addCustomSeed, removeCustomSeed, saveCustomSeeds } from '../reducers/seeds/seedsActions';

const CustomSeeds = () => {
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

  // const [seedRunningStatus, setSeedRunningStatus] = useState(false);
  // const [seedRunningMsg, setSeedRunningMsg] = useState('Seeds running');
  const [seedByType, setSeedByType] = useState({});

  const theState = useSelector((state) => state);
  console.log(theState.testSeeds.seeds);
  const dispatch = useDispatch();

  const onChangeCaseType = (type, inputKey, value) => {
    setSeedByType(prevState => ({
      ...prevState,
      [type]: {
        ...(prevState[type] || {}),
        [inputKey]: value
      }
    }));
  };

  const reseedByCaseType = (type) => {

    const caseType = seedByType[type];
    caseType.seed_type = type;

    dispatch(addCustomSeed(caseType));

    // ApiUtil.post('/seeds/run-demo', { data: caseType })
    //   .then(() => {
    //     setSeedRunningStatus(false);
    //     setReseedingStatus(prevState => ({
    //       ...prevState,
    //       [type]: false
    //     }));
    //   })
    //   .catch(err => {
    //     console.warn(err);
    //     setSeedRunningStatus(false);
    //     setReseedingStatus(prevState => ({
    //       ...prevState,
    //       [type]: false
    //     }));
    //   });
  };

  const saveSeeds = () => {
    dispatch(saveCustomSeeds(theState.testSeeds.seeds));
  };

  const seedTypes = Object.keys(CUSTOM_SEEDS);

  return (
    <div>
      <>
        <h2 id="run_custom_seeds">{COPY.TEST_SEEDS_CUSTOM_SEEDS}</h2>
        <table className="seed-table-style">
          <thead>
            <tr>
              <th className={cx('table-header-styling')}>Case Type</th>
              <th className={cx('table-header-styling')}>Number of cases to create</th>
              <th className={cx('table-header-styling')}>Days Ago</th>
              <th className={cx('table-header-styling')}>Judge CSS_ID (optional)</th>
              <th className={cx('table-header-styling')}></th>
            </tr>
          </thead>
          <tbody>
            {seedTypes.map(type => (
              <tr key={type}>
                <td>{CUSTOM_SEEDS[type]}</td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-num-field')}>
                    <NumberField
                      ariaLabelText={`seed-count-${type}`}
                      useAriaLabel
                      inputID={`seed-count-${type}`}
                      onChange={value => onChangeCaseType(type, 'seed_count', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-num-field')}>
                    <NumberField
                      ariaLabelText={`days-ago-${type}`}
                      useAriaLabel
                      inputID={`days-ago-${type}`}
                      onChange={value => onChangeCaseType(type, 'days_ago', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-cssid-field')}>
                    <TextField
                      ariaLabelText={`css-id-${type}`}
                      useAriaLabel
                      inputID={`css-id-${type}`}
                      onChange={value => onChangeCaseType(type, 'judge_css_id', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className="cf-add-comment-button">
                    <Button onClick={() => reseedByCaseType(type)}>
                      <span>
                        <PlusIcon size={24} />
                      </span>
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <hr />
      </>
      <div className="custom-seeds-preview">
        <h2 id="show_seeds_preview">Preview</h2>
        <div className="preview-table-scroll">
          <table className="seed-table-style preview-table">
            <thead>
              <tr>
                <th className={cx('table-header-styling')}>Case(s) Type</th>
                <th className={cx('table-header-styling')}>Amount</th>
                <th className={cx('table-header-styling')}>Days Ago</th>
                <th className={cx('table-header-styling')}>Associated Judge</th>
              </tr>
            </thead>
            <tbody>
              {theState.testSeeds.seeds.map((obj, index) => (
                <tr key={index}>
                  <td>{obj.seed_type}</td>
                  <td>{obj.seed_count} Cases</td>
                  <td>{obj.days_ago} Days Ago</td>
                  <td>{obj.judge_css_id}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="cf-btn-link lever-right test-seed-button-style cf-right-side">
          <Button onClick={() => saveSeeds()} name={`Create ${theState.testSeeds.seeds.length} test cases`} />
        </div>
      </div>
    </div>
  );
};

export default CustomSeeds;
