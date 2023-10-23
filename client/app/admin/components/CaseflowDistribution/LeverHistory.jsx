/* eslint-disable func-style */
import React from 'react';
import PropTypes from 'prop-types';

const LeverHistory = (props) => {
  return (
    <div>
      <div>{props.historyData.map((entry) =>
        <tr>
          <td>{entry.created_at}</td>
          <td>{entry.user}</td>
          <td>
            <ol>
              {entry.titles.map((title) => {
                return <li>{title}</li>;
              })
              }
            </ol>
          </td>
          <td>
            <ol>
              {entry.original_values.map((originalValue, index) => {
                return <li>{originalValue}{' '}{entry.units[index]}</li>;
              })
              }
            </ol>
          </td>
          <td>
            <ol>
              {entry.current_values.map((currentValue, index) => {
                return <li>{currentValue}{' '}{entry.units[index]}</li>;
              })
              }
            </ol>
          </td>
        </tr>)}
      </div>
    </div>
  );
};

LeverHistory.propTypes = {
  historyData: PropTypes.array,
};

export default LeverHistory;
