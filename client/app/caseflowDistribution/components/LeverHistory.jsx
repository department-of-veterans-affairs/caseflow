/* eslint-disable func-style */
import React from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/LeverHistory.module.scss';

const LeverHistory = (props) => {

  console.log(props.historyData);
  // let historyEntries = [
  //   {
  //     created_at: props.historyData.created_at,
  //     user: props.historyData.user_name,
  //     titles: [props.historyData.title],
  //     original_values: [props.historyData.previous_value],
  //     units: ['TEST UNITS'],
  //     current_values: [props.historyData.update_value]

  //   }
  // ];
  let historyEntries = [];

  return (
    <div>
      <table>
        <tbody>
          <tr>
            <th className={styles.leverHistoryTableHeaderStyling}>Date of Last Change</th>
            <th className={styles.leverHistoryTableHeaderStyling}>User ID</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Data Element Changed</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Previous Value</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Updated Value</th>
          </tr>
        </tbody>
        <tbody>{historyEntries.map((entry, index) =>
          <tr key={index}>
            <td className={styles.historyTableStyling}>{entry.created_at}</td>
            <td className={styles.historyTableStyling}>{entry.user}</td>
            <td className={styles.historyTableStyling}>
              <ol>
                {entry.titles.map((title) => {
                  return <li key={title}>{title}</li>;
                })
                }
              </ol>
            </td>
            <td className={styles.historyTableStyling}>
              <ol>
                {entry.original_values.map((originalValue, idx) => {
                  return <li key={originalValue}>{originalValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
            <td className={styles.historyTableStyling}>
              <ol>
                {entry.current_values.map((currentValue, idx) => {
                  return <li key={currentValue}>{currentValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
          </tr>)}
        </tbody>
      </table>
    </div>
  );
};

LeverHistory.propTypes = {
  historyData: PropTypes.array,
};

export default LeverHistory;
