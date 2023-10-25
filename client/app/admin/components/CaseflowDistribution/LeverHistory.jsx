/* eslint-disable func-style */
import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const LeverHistory = (props) => {

  const leverHistoryStyling = css({
    borderLeft: '0',
    borderRight: '0',
    borderBottom: '0',
    paddingTop: '0',
    marginTop: '0',
    paddingBottom: '0',
    verticalAlign: 'text-top',
    fontFamily: 'Source Sans Pro',
    fontWeight: '400',
    fontSize: '17px',
    lineHeight: '1.5em/33px'
  });

  return (
    <div>
      <table>
        <tbody>{props.historyData.map((entry, index) =>
          <tr key={index}>
            <td {...leverHistoryStyling}>{entry.created_at}</td>
            <td {...leverHistoryStyling}>{entry.user}</td>
            <td {...leverHistoryStyling}>
              <ol {...leverHistoryStyling}>
                {entry.titles.map((title) => {
                  return <li key={title}>{title}</li>;
                })
                }
              </ol>
            </td>
            <td {...leverHistoryStyling}>
              <ol {...leverHistoryStyling}>
                {entry.original_values.map((originalValue, index) => {
                  return <li key={originalValue}>{originalValue}{' '}{entry.units[index]}</li>;
                })
                }
              </ol>
            </td>
            <td {...leverHistoryStyling}>
              <ol {...leverHistoryStyling}>
                {entry.current_values.map((currentValue, index) => {
                  return <li key={currentValue}>{currentValue}{' '}{entry.units[index]}</li>;
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
