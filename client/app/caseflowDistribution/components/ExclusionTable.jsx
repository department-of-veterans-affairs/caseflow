
import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import styles from 'app/styles/caseDistribution/ExclusionTable.module.scss';

const ExclusionTable = () => {

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
      <table>
        <tbody>
          <th className={styles.tableHeaderStyling}>{' '}</th>
          <th className={styles.tableHeaderStyling}>All Legacy Hearings</th>
          <th className={styles.tableHeaderStyling}>All AMA Hearings</th>
          <th className={styles.tableHeaderStyling}>All AMA Direct Review Cases</th>
          <th className={styles.tableHeaderStyling}>All AMA Evidence Submission Cases</th>
        </tbody>
        <tbody>
          <tr>
            <td className={styles.exclusionTableStyling}>
              <h4 className={styles.exclusionTableHeaderStyling}>All Non-priority</h4>
              <ToggleSwitch
                id = "All Non-priority"
                selected = {false}
                disabled
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
          </tr>
          <tr>
            <td className={styles.exclusionTableStyling}>
              <h4 className={styles.exclusionTableHeaderStyling}>All Priority</h4>
              <ToggleSwitch
                id = "All Priority"
                selected = {false}
                disabled
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
            <td className={styles.exclusionTableStyling}>
              <RadioField
                name=""
                options={options}
                vertical
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

  );
};

export default ExclusionTable;
