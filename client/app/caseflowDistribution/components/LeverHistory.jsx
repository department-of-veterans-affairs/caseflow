/* eslint-disable func-style */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import styles from 'app/styles/caseDistribution/LeverHistory.module.scss';

const LeverHistory = (props) => {
  const { leverStore } = props;
  const uniqueTimestamps = [];

  props.historyData.map((entry) => {
    let findTimestamp = uniqueTimestamps.find((x) => x === entry.created_at);

    if (!findTimestamp) {
      uniqueTimestamps.push(entry.created_at);
    }

    return null;
  });

  const getUnitsFromLever = (lever) => {

    const doesDatatypeRequireComplexLogic = lever.data_type === 'radio' || lever.data_type === 'combination';

    if (doesDatatypeRequireComplexLogic) {

      // let selectedOption = lever.options.find((option) => option.item === lever.value);

      // if (selectedOption.data_type === 'number') {
      //   return selectedOption.unit;
      // }

      return '';

    }

    return lever.unit;

  };

  const getLeverTitlesAtTimestamp = (timestamp) => {

    let titles = [];

    props.historyData.forEach((entry) => {
      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        titles.push(entry.title);
      }
    });

    return titles;
  };

  const getLeverUnitsAtTimestamp = (timestamp) => {
    let units = [];

    props.historyData.map((entry) => {
      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        let leverEntry = leverStore.getState().levers.find((lever) => lever.title === entry.title);
        let unit = getUnitsFromLever(leverEntry);

        units.push(unit);
      }

      return null;
    });

    return units;
  };

  const getPreviousValuesAtTimestamp = (timestamp) => {

    let previousValues = [];

    props.historyData.map((entry) => {

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

    props.historyData.map((entry) => {

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

    props.historyData.map((entry) => {

      let sameTimestamp = entry.created_at === timestamp;

      if (sameTimestamp) {
        user = entry.user_name;
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
  }, [props.historyData]);

  let history = formatHistoryData();

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
        <tbody>{history.map((entry, index) =>
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
  historyData: PropTypes.array,
  leverStore: PropTypes.any,
};

export default LeverHistory;
