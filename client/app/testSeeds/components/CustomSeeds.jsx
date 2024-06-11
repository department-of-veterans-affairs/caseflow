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
import { TrashcanIcon } from 'app/components/icons/TrashcanIcon';
import { addCustomSeed, removeCustomSeed, saveCustomSeeds, resetCustomSeeds } from '../reducers/seeds/seedsActions';
import FileUpload from '../../components/FileUpload';

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
  const [file, setFile] = useState(null);

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

  //file upload component

  const handleFileChange = (fileData) => {
    const { file, fileName } = fileData;
    console.log( "fileData", fileData);
    console.log( "file", file);
    setFile(fileData);
    parseCSV(file);
  };

  const parseCSV = (file) => {
    const base64Content = file.split(",")[1];
    const csvText = atob(base64Content);
    const rows = csvText.split('\n').map(row => row.trim().split(','));
    const headers = rows[0].map(header => header.trim());
    const jsonData = rows.slice(1).map(row => {
      const obj = {};
      headers.forEach((header, index) => {
        // obj[header] = row[index] ? row[index].trim() : '';
        const col_value = row[index] ? row[index].trim() : '';
        switch (header) {
          case 'Case(s) Type':
            obj['seed_type'] = col_value;
          case 'Amount':
            obj['seed_count'] = parseInt(col_value);
          case 'Days Ago':
            obj['days_ago'] = parseInt(col_value);
          case 'Associated Judge':
            obj['judge_css_id'] = col_value;
        }

      });
      dispatch(addCustomSeed(obj));
      return obj;
    });
    console.log(jsonData);
  };

  const downloadTemplate = () => {
    window.location.href = `${window.location.origin}/sample_custom_seeds.csv`;
  }

  const resetPreviewSeeds = () => {
    dispatch(resetCustomSeeds());
  }

  const removePreviewSeed = (seed, index) => {
    dispatch(removeCustomSeed(seed, index));
  }

  const resetAllAppeals = () => {

    ApiUtil.get('/seeds/reset_all_appeals')
      .then(() => {
        console.log('Reset all appeals')
      })
      .catch(err => {
        console.warn(err);
      });
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
      <div className='cf-section-header'>
        <div className="cf-right-side">
          <a href="/appeals-ready-to-distribute?csv=1">
            <button className="usa-button-active usa-button">Download Appeals Ready to Distribute CSV</button>
          </a>
        </div>
      </div>
      <div className='custom-seed-button-section' >
        <div className='cf-btn-link upload-seed-csv-button'>
            <FileUpload
              preUploadText="Upload Test Cases CSV"
              postUploadText="Choose a different file"
              id="seed_file_upload"
              fileType=".csv"
              onChange={handleFileChange}
              value={file}
            />
        </div>
        <div className="cf-btn-link lever-right test-seed-button-style cf-right-side">
          <Button onClick={() => downloadTemplate()} name={`Download Template`} />
        </div>
      </div>
      <div className="cf-left-side">
          <h2 id="run_custom_seeds">{COPY.TEST_SEEDS_CUSTOM_SEEDS}</h2>
      </div>
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
                <th className={cx('table-header-styling')}>
                  <div>
                    <Button onClick={() => resetPreviewSeeds()} name={`reset form`} />
                  </div>
              </th>
              </tr>
            </thead>
            <tbody>
              {theState.testSeeds.seeds.map((obj, index) => (
                <tr key={index}>
                  <td>{obj.seed_type}</td>
                  <td>{obj.seed_count} Cases</td>
                  <td>{obj.days_ago} Days Ago</td>
                  <td>{obj.judge_css_id}</td>
                  <td>
                    <div>
                      <span onClick={() => removePreviewSeed(obj, index)}>
                        <TrashcanIcon size={24} />
                      </span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="cf-btn-link lever-left test-seed-button-style cf-left-side">
          <Button onClick={() => resetAllAppeals()} name={`Reset all appeals`} />
        </div>
        <div className="cf-btn-link lever-right test-seed-button-style cf-right-side">
          <Button onClick={() => saveSeeds()} name={`Create ${theState.testSeeds.seeds.length} test cases`} />
        </div>
      </div>
    </div>
  );
};

export default CustomSeeds;
