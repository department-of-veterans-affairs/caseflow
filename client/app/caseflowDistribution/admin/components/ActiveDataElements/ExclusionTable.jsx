import React from 'react';
import PropTypes from 'prop-types';

import ToggleSwitch from '../../../../components/ToggleSwitch/ToggleSwitch';
import RadioField from '../../../../components/RadioField';
import styles from '../../../../styles/caseDistribution/ExclusionTable.module.scss';

import COPY from '../../../../../COPY';

export const ExclusionTable = (props) => {
  // TODO
  let isMemberUser = false;

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
      <h2>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_TITLE}</h2>

      <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION}</p>
      <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_DESCRIPTION_NOTE}</p>
      <table >
        <tbody>
          <tr>
            <th className={styles.tableHeaderStyling}>{' '}</th>
            <th className={styles.tableHeaderStyling}>Legacy Appeals</th>
            <th className={styles.tableHeaderStyling}>AMA Appeals</th>
            <th className={styles.tableHeaderStyling}>AMA Direct Review Appeals</th>
            <th className={styles.tableHeaderStyling}>AMA Evidence Submission Appeals</th>
          </tr>
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
