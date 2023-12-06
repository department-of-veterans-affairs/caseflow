
import PropTypes from 'prop-types';
import * as React from 'react';
import moment from 'moment';
import { capitalize, startCase } from 'lodash';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const detailKeys = ['benefitType', 'issueType', 'issueDescription', 'decisionDate'];

const DetailsList = ({ event }) => {

  const formatValue = (key, value) => {
    if (key === 'decisionDate') {
      return moment(value).utc().
        format('MM/DD/YY');
    }

    if (key === 'benefitType') {
      return BENEFIT_TYPES[value] || value;
    }

    return value;
  };

  const listStyle = {
    display: 'block',
    lineHeight: 1
    // marginBottom: '10px'
  };

  const detailsObject = Object.entries(event).
    filter(([key]) => detailKeys.includes(key)).
    reduce((obj, [key, value]) => {
      obj[key] = value;

      return obj;
    }, {});

  return (
    <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
      {Object.entries(detailsObject).
        map(([key, value]) => (
          <li key={key} style={listStyle}>
            <strong>{capitalize(startCase(key))}:</strong> {formatValue(key, value)}
          </li>
        ))}
      {event.readableEventType === 'Withdrew issue' && (
        <li key="withdrawnDate" style={listStyle}>
          <strong>Withdrawl request date:</strong> {moment(event.withdrawlRequestDate).utc().
            format('MM/DD/YY')}
        </li>
      )}
      {event.readableEventType === 'Removed issue' && (
        <li key="removedDate" style={listStyle}>
          <strong>Removed request date:</strong> {moment(event.eventDate).utc().
            format('MM/DD/YY')}
        </li>
      )}
      {event.readableEventType === 'Completed disposition' && (
        <>
          <li key="disposition" style={listStyle}>
            <strong>Disposition:</strong> {event.disposition}
          </li>
          <li key="decisionDescription" style={listStyle}>
            <strong>Decision description:</strong> {event.decisionDescription}
          </li>
        </>
      )}
    </ul>
  );
};

DetailsList.propTypes = {
  event: PropTypes.shape({
    details: PropTypes.shape({
      benefitType: PropTypes.string,
      issueType: PropTypes.string,
      decisionDescription: PropTypes.string,
      disposition: PropTypes.string,
    }),
    disposition: PropTypes.string,
    decisionDescription: PropTypes.string,
    eventType: PropTypes.string,
    eventDate: PropTypes.any,
    readableEventType: PropTypes.string,
    withdrawlRequestDate: PropTypes.any
  })
};

const renderEventDetails = (event) => {
  let renderBlock = null;

  // console.log(event);

  switch (event.eventType) {
  case 'added_decision_date':
  case 'added_issue':
  case 'added_issue_without_decision_date':
  case 'completed_disposition':
  case 'withdrew_issue':
  case 'removed_issue':
    renderBlock = <DetailsList event={event} />;
    break;

  case 'claim_creation':
    // console.log('in claim_createion?');
    renderBlock = 'Claim created.';
    break;

  case 'completed':
    renderBlock = <>
      <span>Claim closed.</span>
      <br />
      <span><strong>Claim decision date:</strong> {moment(event.dispositionDate).utc().
        format('MM/DD/YY')}</span>
    </>;
    break;

  case 'cancelled':
    renderBlock = 'Claim closed.';
    break;

  case 'incomplete':
    renderBlock = 'Claim can not be processed until decision date is entered.';
    break;

  case 'in_progress':
    renderBlock = 'Claim can be processed';
    break;

  default:
    // Code to handle unexpected keys
    renderBlock = 'Unknown event type';
    break;
  }

  // console.log('last thing before death?');

  return renderBlock;

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
    valueFunction: (event) => {
      // console.log(event);

      return event.eventUserName;
    },
    getSortValue: (event) => event.eventUserName
  };
};

export const dateTimeColumn = () => {
  return {
    header: 'Date and Time',
    name: 'dateTime',
    valueFunction: (event) => {
      // console.log(event);

      return moment(event.eventDate).utc().
        format('MM/DD/YY, HH:mm');
    },
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
    valueFunction: (event) => event.readableEventType,
    getSortValue: (event) => event.readableEventType
  };
};

// TODO: This is the column that needs the most work since the display will change based on the activity type
export const detailsColumn = () => {
  return {
    header: 'Details',
    name: 'details',
    valueFunction: (event) => {
      const stuff = renderEventDetails(event);

      // console.log(stuff);

      return stuff;
    }
  };
};

export const taskIdColumn = () => {
  return {
    header: 'Task ID',
    name: 'taskID',
    valueFunction: (event) => {
      // console.log(event);

      return <a href={`/decision_reviews/${event.benefitType}/tasks/${event.taskID}`}>{event.taskID}</a>;
    }
  };
};

export const claimantNameColumn = () => {
  return {
    header: 'Claimant',
    name: 'claimant',
    valueFunction: (event) => event.claimantName,
    getSortValue: (event) => event.claimantName
  };
};
