import React from 'react';
import PropTypes from 'prop-types';

const TIMING_SPECIFIC_OPTIONS: [
  {
    "label": "After",
    "id": "after"
  },
  {
    "label": "Before",
    "id": "before"
  },
  {
    "label": "Between",
    "id": "between"
  },
  {
    "label": "Last 7 Days",
    "id": "last_7_days"
  },
  {
    "label": "Last 30 Days",
    "id": "last_30_days"
  },
  {
    "label": "Last 365 Days",
    "id": "last_365_days"
  },
]

export const TimingSpecification = (display = true) => {

  return (
    <>
      <hr style={{ marginTop: '50px', marginBottom: '50px' }} />
      <h1>Timing specifications</h1>
    </>
  );
};

TimingSpecification.propTypes = {
  display: PropTypes.bool,
};

export default TimingSpecification;
