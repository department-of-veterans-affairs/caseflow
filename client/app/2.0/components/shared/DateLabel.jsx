// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

/**
 * Date Label -- Formats a date and makes it bold
 * @param {Object} props -- Contains the date to format
 */
export const DateLabel = ({ date }) => (
  <div className="comment-relevant-date">
    {date && <strong>{moment(date).format('MM/DD/YYYY')}</strong>}
  </div>
);

DateLabel.propTypes = {
  date: PropTypes.string,
};
