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
  const [seedByType, setSeedByType] = useState({});
  const [inputFile, setFile] = useState(null);

  const theState = useSelector((state) => state);
  const dispatch = useDispatch();

  const onChangeCaseType = (type, inputKey, value) => {
    setSeedByType((prevState) => ({
      ...prevState,
      [type]: {
        ...(prevState[type] || {}),
        [inputKey]: value
      }
    }));
  };

  // file upload component

  const parseCSV = (file) => {
    const base64Content = file.split(',')[1];
    const csvText = atob(base64Content);
    const rows = csvText.split('\n').map((row) => row.trim().split(','));
    const headers = rows[0].map((header) => header.trim());

    rows.slice(1).map((row) => {
      const obj = {};

      headers.forEach((header, index) => {
        const colValue = row[index] ? row[index].trim() : '';

        switch (header) {
        case 'Case(s) Type':
          obj.seed_type = colValue;
          break;

        case 'Amount':
          obj.seed_count = Number(colValue);
          break;

        case 'Days Ago':
          obj.days_ago = Number(colValue);
          break;

        case 'Associated Judge':
          obj.judge_css_id = colValue;
          break;

        case 'Disposition':
          obj.disposition = colValue;
          break;

        case 'Hearing Type':
          obj.hearing_type = colValue;
          break;

        case 'Date/Time of Hearing':
          obj.hearing_date = colValue;
          break;

        case 'AOD based on age':
          obj.aod_based_on_age = Number(colValue);
          break;

        case 'Regional Office':
          obj.closest_regional_office = colValue;
          break;

        case 'UUID':
          obj.uuid = colValue;
          break;

        case 'Docket':
          obj.docket = colValue;
          break;

        default:
          break;
        }
      });
      dispatch(addCustomSeed(obj));

      return obj;
    });
  };

  const handleFileChange = (fileData) => {
    const { file } = fileData;

    setFile(fileData);
    parseCSV(file);
  };

  const downloadTemplate = () => {
    window.location.href = `${window.location.origin}/sample_custom_seeds.csv`;
  };

  const resetPreviewSeeds = () => {
    dispatch(resetCustomSeeds());
  };

  const removePreviewSeed = (seed, index) => {
    dispatch(removeCustomSeed(seed, index));
  };

  const resetAllAppeals = () => {
    ApiUtil.get('/seeds/reset_all_appeals');
  };

  const reseedByCaseType = (type) => {

    const caseType = seedByType[type];

    caseType.seed_type = type;

    dispatch(addCustomSeed(caseType));
  };

  const saveSeeds = () => {
    dispatch(saveCustomSeeds(theState.testSeeds.seeds));
  };

  const seedTypes = Object.keys(CUSTOM_SEEDS);

  return (
    <div>
      <>
        <div className="cf-section-header">
          <div className="cf-right-side">
            <a href="/case_distribution_levers_tests/appeals_ready_to_distribute?csv=1">
              <button className="usa-button-active usa-button">Download Appeals Ready to Distribute CSV</button>
            </a>
          </div>
        </div>
        <div className="custom-seed-button-section" >
          <div className="cf-btn-link upload-seed-csv-button">
            <FileUpload
              preUploadText="Upload Test Cases CSV"
              postUploadText="Choose a different file"
              id="seed_file_upload"
              fileType=".csv"
              onChange={handleFileChange}
              value={inputFile}
            />
          </div>
          <div className="cf-btn-link lever-right test-seed-button-style cf-right-side">
            <Button onClick={() => downloadTemplate()} name="Download Template" />
          </div>
          {/* wiki Link to be implemented */}
          {/* <div className='cf-right-side'>
          <a href='#'>wiki</a>
        </div> */}
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
            {seedTypes.map((type) => (
              <tr key={type}>
                <td>{CUSTOM_SEEDS[type]}</td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-num-field')}>
                    <NumberField
                      ariaLabelText={`seed-count-${type}`}
                      useAriaLabel
                      inputID={`seed-count-${type}`}
                      onChange={(value) => onChangeCaseType(type, 'seed_count', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-num-field')}>
                    <NumberField
                      ariaLabelText={`days-ago-${type}`}
                      useAriaLabel
                      inputID={`days-ago-${type}`}
                      onChange={(value) => onChangeCaseType(type, 'days_ago', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className={cx('lever-right', 'test-seeds-cssid-field')}>
                    <TextField
                      ariaLabelText={`css-id-${type}`}
                      useAriaLabel
                      inputID={`css-id-${type}`}
                      onChange={(value) => onChangeCaseType(type, 'judge_css_id', value)}
                    />
                  </div>
                </td>
                <td>
                  <div className="cf-add-comment-button">
                    <Button
                      id={`btn-${type}`}
                      dataTestid={`btn-${type}`}
                      onClick={() => reseedByCaseType(type)}
                      name={`add-${type}`}
                    >
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
          <table className="seed-table-style preview-table" id="preview-table">
            <thead>
              <tr>
                <th className={cx('table-header-styling')}>Case(s) Type</th>
                <th className={cx('table-header-styling')}>Amount</th>
                <th className={cx('table-header-styling')}>Days Ago</th>
                <th className={cx('table-header-styling')}>Associated Judge</th>
                <th className={cx('table-header-styling')}>Disposition</th>
                <th className={cx('table-header-styling')}>Hearing Type</th>
                <th className={cx('table-header-styling')}>Date/Time of Hearing</th>
                <th className={cx('table-header-styling')}>AOD based on age</th>
                <th className={cx('table-header-styling')}>Regional Office</th>
                <th className={cx('table-header-styling')}>UUID</th>
                <th className={cx('table-header-styling')}>Docket</th>
                <th className={cx('table-header-styling')}>
                  <div>
                    <Button onClick={() => resetPreviewSeeds()} name="reset form" />
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
                  <td>{obj.disposition}</td>
                  <td>{obj.hearing_type}</td>
                  <td>{obj.hearing_date}</td>
                  <td>{obj.aod_based_on_age}</td>
                  <td>{obj.closest_regional_office}</td>
                  <td>{obj.uuid}</td>
                  <td>{obj.docket}</td>
                  <td>
                    <div>
                      <span id={`del-preview-row-${index}`} onClick={() => removePreviewSeed(obj, index)}>
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
          <Button onClick={() => resetAllAppeals()} name="Reset all appeals" />
        </div>
        <div className="cf-btn-link lever-right test-seed-button-style cf-right-side">
          <Button onClick={() => saveSeeds()} name={`Create ${theState.testSeeds.seeds.length} test cases`} />
        </div>
      </div>
    </div>
  );
};

export default CustomSeeds;
