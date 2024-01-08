import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import PropTypes from 'prop-types';
import RadioField from 'app/components/RadioField';
import styles from 'app/styles/caseDistribution/ExclusionTable.module.scss';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';

const ExclusionTable = (props) => {
  let isMemberUser = !props.isAdmin;
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
        <tbody>
          <tr>
            <th className={styles.tableHeaderStyling}>{' '}</th>
            <th className={styles.tableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}</th>
            <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}</th>
            <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER}</th>
          </tr>
          <tr>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3> :
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
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
          </tr>
          <tr>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3> :
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
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

ExclusionTable.propTypes = {
  isAdmin: PropTypes.bool.isRequired,
};
export default ExclusionTable;
