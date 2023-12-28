import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/LeverHistory.module.scss';

const LeverHistory = (props) => {
  const { leverStore } = props;
  const [historyData, setHistoryData] = React.useState([]);

  function formatHistoryData(historyEntries) {
    if (!historyEntries) return [];
    const formatted = historyEntries.reduce((accumulator, entry) => {
      const existingEntry = accumulator.find(
        (item) => item.created_at === entry.created_at && item.user_id === entry.user_id
      );

      if (existingEntry) {
        existingEntry.titles.push(entry.title);
        existingEntry.previous_values.push(entry.previous_value);
        existingEntry.updated_values.push(entry.update_value);
        existingEntry.units.push(entry.unit || 'null');
      } else {
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
    return formatted;
  }

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const historyEntries = leverStore.getState().formatted_history;
      const formattedEntries = formatHistoryData(historyEntries);
      setHistoryData(formattedEntries);
    });

    return () => {
      unsubscribe();
    };
  }, [leverStore]);

  return (
    <div>
      <table key={historyData.length}>
        <tbody>
          <tr>
            <th className={styles.leverHistoryTableHeaderStyling}>Date of Last Change</th>
            <th className={styles.leverHistoryTableHeaderStyling}>User ID</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Data Element Changed</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Previous Value</th>
            <th className={styles.leverHistoryTableHeaderStyling}>Updated Value</th>
          </tr>
        </tbody>
        <tbody key={historyData.length}>
          {historyData &&
            historyData.map((entry, index) => (
              <tr key={`${historyData.length}-${index}`}>
                <td className={styles.historyTableStyling}>{entry.created_at}</td>
                <td className={styles.historyTableStyling}>{entry.user_name}</td>
                <td className={styles.historyTableStyling}>
                  <ol>
                    {entry.titles.map((title) => (
                      <li key={title}>{title}</li>
                    ))}
                  </ol>
                </td>
                <td className={styles.historyTableStyling}>
                  <ol>
                    {entry.previous_values.map((previousValue, idx) => (
                      <li key={previousValue}>{previousValue}{' '}{entry.units[idx]}</li>
                    ))}
                  </ol>
                </td>
                <td className={styles.historyTableStyling}>
                  <ol>
                    {entry.updated_values.map((updatedValue, idx) => (
                      <li key={updatedValue}>{updatedValue}{' '}{entry.units[idx]}</li>
                    ))}
                  </ol>
                </td>
              </tr>
            ))}
        </tbody>
      </table>
    </div>
  );
};

LeverHistory.propTypes = {
  leverStore: PropTypes.any,
};

export default LeverHistory;
