/* eslint-disable func-style */
import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/LeverHistory.module.scss';

const LeverHistory = (props) => {
  const { leverStore } = props;
  const historyEntries = leverStore.getState().formatted_history
  const [historyData, setHistoryData] = React.useState([]);
  const [history, setHistory] = useState([]);
  const [historySize, setHistorySize] = useState(0);


  function formatHistoryData(historyEntries) {

    if (!historyEntries) return [];

   const formatted = historyEntries.reduce((accumulator, entry) => {
    // Find an existing entry in the accumulator with the same timestamp and user
    const existingEntry = accumulator.find(
      (item) => item.created_at === entry.created_at && item.user_id === entry.user_id
    );
    // If an existing entry is found, update its values
    if (existingEntry) {
      existingEntry.titles.push(entry.title);
      existingEntry.previous_values.push(entry.previous_value);
      existingEntry.updated_values.push(entry.update_value);
      existingEntry.units.push(entry.unit || 'null');
    } else {
      // If no existing entry is found, create a new entry
      const newEntry = {
        created_at: entry.created_at,
        user_id: entry.user_id,
        user_name: entry.user_name,
        titles: [entry.title],
        previous_values: [entry.previous_value],
        updated_values: [entry.update_value],
        units: [entry.unit || 'null'],
      };
      accumulator.push(newEntry);
    }
    return accumulator;
  }, []);
  return formatted
}

  useEffect(() => {
    // Format the historyData based on the changes in formatted_history
    const formattedEntries = formatHistoryData(historyEntries);
    // Update the component state with the formatted history data
    setHistoryData(formattedEntries);
  }, [historyEntries]);

  return (
    <div>
      <table key={historySize}>
        <tbody>
          <tr>
            <th className={styles.leverHistoryTableHeaderStyling}>Date of Last Change</th>
            <th className={styles.leverHistoryTableHeaderStyling}>User ID</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Data Element Changed</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Previous Value</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Updated Value</th>
          </tr>
        </tbody>
        <tbody key={historySize}>{historyData && historyData.map((entry, index) =>
          <tr key={`${historySize}-${index}`}>
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
                {entry.previous_values.map((previousValue, idx) => {
                  return <li key={previousValue}>{previousValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
            <td className={styles.historyTableStyling}>
              <ol>
                {entry.updated_values.map((updatedValue, idx) => {
                  return <li key={updatedValue}>{updatedValue}{' '}{entry.units[idx]}</li>;
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
  leverStore: PropTypes.any,
};

export default LeverHistory;
