/* eslint-disable func-style */
import React from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/LeverHistory.module.scss';
import { getLeverHistoryTable } from '../reducers/levers/leversSelector';
import COPY from '../../../COPY';

const LeverHistory = () => {

  const theState = useSelector((state) => state);

  const leverHistoryTable = getLeverHistoryTable(theState);

  return (
    <div>
      <table>
        <tbody>
          <tr>
            <th className={styles.leverHistoryTableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_DATE}
            </th>
            <th className={styles.leverHistoryTableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_USER}
            </th>
            <th className={styles.leverHistoryTableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_DATA_ELEMENT}
            </th>
            <th className={styles.leverHistoryTableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_PREV_VALUE}
            </th>
            <th className={styles.leverHistoryTableHeaderStyling}>
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_UPDATED_VALUE}
            </th>
          </tr>
        </tbody>
        <tbody>{leverHistoryTable.map((entry, index) =>
          <tr key={index}>
            <td className={styles.historyTableStyling}>{entry.created_at}</td>
            <td className={styles.historyTableStyling}>{entry.user_id}</td>
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
