/* eslint-disable func-style */
import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const LeverHistory = (props) => {

  const historyTableStyling = css({
    paddingTop: '0',
    marginTop: '0',
    paddingBottom: '0',
    borderLeft: '0',
    borderRight: '0',
    borderTop: '0',
    borderColor: '#d6d7d9;',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: '400',
    fontSize: '19px',
    lineHeight: '1.3em/25px',
    width: '20%'
  });

  const leverHistoryTableHeaderStyling = css({
    borderLeft: '0',
    borderRight: '0',
    borderTop: '0',
    borderColor: '#d6d7d9;',
    fontFamily: 'Source Sans Pro',
    fontWeight: '700',
    fontSize: '19px',
    lineHeight: '1.3em/25px'
  });

  return (
    <div>
      <table>
        <tbody>
          <tr>
            <th {...leverHistoryTableHeaderStyling}>Date of Last Change</th>
            <th {...leverHistoryTableHeaderStyling}>User ID</th>
            <th {...leverHistoryTableHeaderStyling}>Data Element Changed</th>
            <th {...leverHistoryTableHeaderStyling}>Previous Value</th>
            <th {...leverHistoryTableHeaderStyling}>Updated Value</th>
          </tr>
        </tbody>
        <tbody>{props.historyData.map((entry, index) =>
          <tr key={index}>
            <td {...historyTableStyling}>{entry.created_at}</td>
            <td {...historyTableStyling}>{entry.user}</td>
            <td {...historyTableStyling}>
              <ol>
                {entry.titles.map((title) => {
                  return <li key={title}>{title}</li>;
                })
                }
              </ol>
            </td>
            <td {...historyTableStyling}>
              <ol>
                {entry.original_values.map((originalValue, idx) => {
                  return <li key={originalValue}>{originalValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
            <td {...historyTableStyling}>
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
