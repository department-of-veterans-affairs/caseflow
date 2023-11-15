
import PropTypes from 'prop-types';
import * as React from 'react';
import moment from 'moment';
import { capitalize, startCase } from 'lodash';

const DetailsList = ({ event }) => {

  const formatValue = (key, value) => {
    if (key === 'decisionDate') {
      return moment(value).utc().
        format('MM/DD/YY');
    }

    return value;
  };

  const listStyle = {
    display: 'block',
    lineHeight: 1
    // marginBottom: '10px'
  };

  // This currently relies on the object.entries remaining in the same order which is not ideal
  // Could probably map into the object based on a keys array instead

  return (
    <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
      {Object.entries(event.details).slice(0, 3).
        map(([key, value]) => (
          <li key={key} style={listStyle}>
            <strong>{capitalize(startCase(key))}:</strong> {formatValue(key, value)}
          </li>
        ))}
      {event.eventType === 'Withdrew Issue' && (
        <li key="withdrawnDate" style={listStyle}>
          <strong>Withdrawl request date:</strong> {moment(event.details.withdrawlRequestDate).utc().
            format('MM/DD/YY')}
        </li>
      )}
      {event.eventType === 'Removed Issue' && (
        <li key="removedDate" style={listStyle}>
          <strong>Removed request date:</strong> {moment(event.details.withdrawlRequestDate).utc().
            format('MM/DD/YY')}
        </li>
      )}
      {event.eventType === 'Completed Disposition' && (
        <>
          <li key="disposition" style={listStyle}>
            <strong>Disposition:</strong> {event.details.disposition}
          </li>
          <li key="decisionDescription" style={listStyle}>
            <strong>Decision description:</strong> {event.details.decisionDescription}
          </li>
        </>
      )}
    </ul>
  );
};

DetailsList.propTypes = {
  event: PropTypes.shape({
    details: PropTypes.shape({
      decisionDescription: PropTypes.any,
      disposition: PropTypes.any,
      withdrawlRequestDate: PropTypes.any
    }),
    eventType: PropTypes.string,
  })
};

const renderEventDetails = (event) => {
  let renderBlock = null;

  switch (event.eventType) {
  case 'Added Decision Date':
  case 'Added Issue':
  case 'Add Issue - No Decision Date':
  case 'Completed Disposition':
  case 'Withdrew Issue':
    renderBlock = <DetailsList event={event} />;
    break;

  case 'Claim Created':
    renderBlock = 'Claim created.';
    break;

  case 'Claim Closed':
    renderBlock = <>
      <span>Claim closed.</span>
      <br />
      <span><strong>Claim decision date:</strong> {moment(event.details.decisionDate).utc().
        format('MM/DD/YY')}</span>
    </>;
    break;

  case 'Claim Status - Incomplete':
    renderBlock = 'Claim can not be processed until decision date is entered.';
    break;

  case 'Claim Status - In Progress':
    renderBlock = 'Claim can be processed';
    break;

  default:
    // Code to handle unexpected keys
    break;
  }

  return renderBlock;

};

// TOOD: This isn't perfect lol
const formatUserName = (userName) => {
  const splitNames = userName.split(' ');
  const last = splitNames.pop();

  return [splitNames.map((remainingName) => `${remainingName[0] }.`), last].join(' ');
};

export const userColumn = (events) => {
  return {
    header: 'User',
    name: 'user',
    enableFilter: true,
    label: 'Filter by user',
    valueName: 'user',
    columnName: 'eventUser',
    tableData: events,
    valueFunction: (event) => formatUserName(event.eventUser),
    getSortValue: (event) => event.eventUser
  };
};

export const dateTimeColumn = () => {
  return {
    header: 'Date and Time',
    name: 'dateTime',
    valueFunction: (event) => moment(event.eventDate).utc().
      format('MM/DD/YY, HH:mm'),
    // Might need to do date stuff to sort as well?
    getSortValue: (event) => event.eventDate
  };
};

export const activityColumn = (events) => {
  return {
    header: 'Activity',
    name: 'activity',
    enableFilter: true,
    label: 'Filter by activity',
    valueName: 'activity',
    columnName: 'eventType',
    anyFiltersAreSet: true,
    tableData: events,
    valueFunction: (event) => event.eventType,
    getSortValue: (event) => event.eventType
  };
};

// TODO: This is the column that needs the most work since the display will change based on the activity type
export const detailsColumn = () => {
  return {
    header: 'Details',
    name: 'details',
    valueFunction: (event) => {
      return renderEventDetails(event);
    }
  };
};
