import React from 'react';
import { useSelector } from 'react-redux';
import { getLeverHistoryTable } from '../reducers/levers/leversSelector';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const LeverHistory = () => {

  const theState = useSelector((state) => state);

  const leverHistoryTable = getLeverHistoryTable(theState);

  const displayValue = (value, entry, idx) => {
    if (entry.leverDataType[idx] === ACD_LEVERS.data_types.radio &&
          (value.toLowerCase().includes('always') || value.toLowerCase().includes('omit'))) {
      return `${value}`;
    }

    return `${value} ${entry.units[idx] === 'null' ? '' : entry.units[idx]}`;
  };

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
                {entry.previousValues.map((previousValue, idx) => {
                  return <li key={`${index}-${previousValue}-${idx}`}>
                    {displayValue(previousValue, entry, idx)}</li>;
                })
                }
              </ol>
            </td>
            <td className="history-table-styling entry-updated-values">
              <ol>
                {entry.updatedValues.map((updatedValue, idx) => {
                  return <li key={`${index}-${updatedValue}-${idx}`}>
                    {displayValue(updatedValue, entry, idx)}</li>;
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
