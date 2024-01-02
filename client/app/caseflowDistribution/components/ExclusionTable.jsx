import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import PropTypes from 'prop-types';
import RadioField from 'app/components/RadioField';
import styles from 'app/styles/caseDistribution/ExclusionTable.module.scss';
import COPY from '../../../COPY';

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
          <th className={styles.tableHeaderStyling}>{' '}</th>
          <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_1}</th>
          <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_2}</th>
          <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_3}</th>
          <th className={styles.tableHeaderStyling}>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_4}</th>
        </tbody>
        <tbody>
          <tr>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <h3>All Non-priority</h3> :
                <span>
                  <h4 className={styles.exclusionTableHeaderStyling}>All Non-priority</h4>
                  <ToggleSwitch
                    id = "All Non-priority"
                    selected = {false}
                    disabled
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <h3>All Priority</h3> :
                <span>
                  <h4 className={styles.exclusionTableHeaderStyling}>All Priority</h4>
                  <ToggleSwitch
                    id = "All Priority"
                    selected = {false}
                    disabled
                  />
                </span>
              }
            </td>
            <td className={`${styles.exclusionTableStyling} ${styles.leverDisabled}`}>
              {isMemberUser ?
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
                <label className={styles.exclusionTableMemberViewStyling}>Off</label> :
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
