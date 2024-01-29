/* eslint-disable func-style */
import React from 'react';
import { useSelector } from 'react-redux';
import { getLeverHistoryTable } from '../reducers/levers/leversSelector';
import COPY from '../../../COPY';

const LeverHistory = () => {

  const theState = useSelector((state) => state);

  const leverHistoryTable = getLeverHistoryTable(theState);

  return (
    <div className="lever-history-styling">
      <table id="lever-history-table">
        <tbody>
          <tr>
            <th className="lever-history-table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_DATE}
            </th>
            <th className="lever-history-table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_USER}
            </th>
            <th className="lever-history-table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_DATA_ELEMENT}
            </th>
            <th className="lever-history-table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_PREV_VALUE}
            </th>
            <th className="lever-history-table-header-styling" scope="column">
              {COPY.CASE_DISTRIBUTION_LEVER_HISTORY_UPDATED_VALUE}
            </th>
          </tr>
        </tbody>
        <tbody>{leverHistoryTable.map((entry, index) =>
          <tr key={index} id={`lever-history-table-row-${index}`}>
            <td className="history-table-styling entry-created-at">{entry.created_at}</td>
            <td className="history-table-styling entry-user-id">{entry.user_css_id}</td>
            <td className="history-table-styling entry-titles">
              <ol>
                {entry.titles.map((title) => {
                  return <li key={title}>{title}</li>;
                })
                }
              </ol>
            </td>
            <td className="history-table-styling entry-previous-values">
              <ol>
                {entry.previous_values.map((previousValue, idx) => {
                  return <li key={`${index}-${previousValue}-${idx}`}>
                    {previousValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
            <td className="history-table-styling entry-updated-values">
              <ol>
                {entry.updated_values.map((updatedValue, idx) => {
                  return <li key={`${index}-${updatedValue}-${idx}`}>
                    {updatedValue}{' '}{entry.units[idx]}</li>;
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

export default LeverHistory;
