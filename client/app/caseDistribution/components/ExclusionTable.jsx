import React from 'react';
import { useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);

  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  // Placeholder options until future implementation
  let options = [
    { displayText: 'On',
      value: '1',
      disabled: true
    },
    { displayText: 'Off',
      value: '2',
      disabled: true
    }
  ];

  const generateUniqueId = (leverItem, optionValue, index) => `${leverItem}-${optionValue}-${index}`;

  return (
    <div className="exclusion-table-container-styling">
      <table >
        <thead>
          <tr>
            <th className="table-header-styling" scope="column">{' '}</th>
            <th className="table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className="table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}
            </th>
            <th className="table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}
            </th>
            <th className="table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER}
            </th>
          </tr>
        </thead>
        {isUserAcdAdmin ?
          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All non-priority">
                <span>
                  <h4 className="exclusion-table-header-styling">
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_non_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All non-priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All non-priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All non-priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All non-priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
            </tr>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All Priority">
                <span>
                  <h4 className="exclusion-table-header-styling">
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All Priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All Priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All Priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')} aria-label="All Priority">
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
            </tr>
          </tbody> :

          <tbody>
            <th aria-label="All Non-Priority"></th>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
            </tr>
            <th aria-label="All Priority"></th>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}</label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
