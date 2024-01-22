/* eslint-disable func-style */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import COPY from '../../../COPY';

const LeverHistory = (props) => {
  const { historyData } = props;
  const uniqueTimestamps = [];

  historyData.map((entry) => {
    let findTimestamp = uniqueTimestamps.find((x) => x === entry.created_at);

    if (!findTimestamp) {
      uniqueTimestamps.push(entry.created_at);
    }

    return null;
  });

  const getUnitsFromLever = (leverDataType, leverUnit) => {

    const doesDatatypeRequireComplexLogic = (leverDataType === ACD_LEVERS.data_types.radio ||
      leverDataType === ACD_LEVERS.data_types.combination);

    if (doesDatatypeRequireComplexLogic) {
      return '';
    }

    return leverUnit;

  };

  const getLeverTitlesAtTimestamp = (timestamp) => {

    let titles = [];

    historyData.forEach((entry) => {
      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        titles.push(entry.lever_title);
      }
    });

    return titles;
  };

  const getLeverUnitsAtTimestamp = (timestamp) => {
    let units = [];

    historyData.map((entry) => {
      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        let unit = getUnitsFromLever(entry.lever_data_type, entry.lever_unit);

        units.push(unit);
      }

      return null;
    });

    return units;
  };

  const getPreviousValuesAtTimestamp = (timestamp) => {

    let previousValues = [];

    historyData.map((entry) => {

      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {

        previousValues.push(entry.previous_value);
      }

      return null;
    });

    return previousValues;
  };

  const getUpdatedValuesAtTimestamp = (timestamp) => {

    let updatedValues = [];

    historyData.map((entry) => {

      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        updatedValues.push(entry.update_value);
      }

      return null;
    });

    return updatedValues;
  };

  const getUserAtTimestamp = (timestamp) => {

    let user = '';

    historyData.map((entry) => {

      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        user = entry.user_css_id;
      }

      return null;
    });

    return user;
  };

  function formatTime(databaseDate) {
    // Create a Date object from the database date string
    const dateObject = new Date(databaseDate);
    // Use toLocaleDateString() to get a localized date string for the United States
    const options = { weekday: 'short', year: 'numeric', month: 'short', day: 'numeric' };
    const datePart = dateObject.toLocaleDateString('en-US', options);
    // Get hours, minutes, and seconds
    const hours = dateObject.getHours();
    const minutes = dateObject.getMinutes();
    const seconds = dateObject.getSeconds();
    // Format the date string
    const formattedDate = `${datePart} ${hours}:${minutes}:${seconds}`;

    return formattedDate;
  }

  const formatHistoryData = () => {

    let formattedHistoryEntries = [];

    let sortedTimestamps = uniqueTimestamps.reverse();

    sortedTimestamps.map((time) => {
      let historyEntry = {
        created_at: formatTime(time),
        user: getUserAtTimestamp(time),
        titles: getLeverTitlesAtTimestamp(time),
        previous_values: getPreviousValuesAtTimestamp(time),
        updated_values: getUpdatedValuesAtTimestamp(time),
        units: getLeverUnitsAtTimestamp(time)
      };

      return formattedHistoryEntries.push(historyEntry);
    });

    return formattedHistoryEntries;
  };

  useEffect(() => {
    formatHistoryData();
  }, [historyData]);

  let history = formatHistoryData();

  return (
    <div className="lever-history-styling">
      <table>
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
        <tbody>{history.map((entry, index) =>
          <tr key={index}>
            <td className="history-table-styling">{entry.created_at}</td>
            <td className="history-table-styling">{entry.user}</td>
            <td className="history-table-styling">
              <ol>
                {entry.titles.map((title) => {
                  return <li key={title}>{title}</li>;
                })
                }
              </ol>
            </td>
            <td className="history-table-styling">
              <ol>
                {entry.previous_values.map((previousValue, idx) => {
                  return <li key={previousValue}>{previousValue}{' '}{entry.units[idx]}</li>;
                })
                }
              </ol>
            </td>
            <td className="history-table-styling">
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
  historyData: PropTypes.array,
  leverStore: PropTypes.any,
};

export default LeverHistory;
