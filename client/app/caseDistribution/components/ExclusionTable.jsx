import React from 'react';
import { useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import styles from 'app/styles/caseDistribution/ExclusionTable.module.scss';
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

  return (
    <div className={styles.exclusionTableContainerStyling}>
      <table >
        <thead>
          <tr>
            <th className={styles.tableHeaderStyling}>{' '}</th>
            <th className={styles.tableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}</th>
            <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}</th>
            <th className={styles.tableHeaderStyling}>AMA DOC</th>
          </tr>
        </thead>
        {isUserAcdAdmin ?
          <tbody>
            <tr>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <h4 className={styles.exclusionTableHeaderStyling}>
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_non_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
            </tr>
            <tr>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <h4 className={styles.exclusionTableHeaderStyling}>
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
            </tr>
          </tbody> :

          <tbody>
            <tr>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <h3>All Non-Priority</h3>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
            </tr>
            <tr>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <h3>All Priority</h3>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>Off</label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>Off</label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>Off</label>
              </td>
              <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
                <label className={styles.exclusionTableMemberViewStyling}>Off</label>
              </td>
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
