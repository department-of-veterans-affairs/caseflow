import React from 'react';
import StaticLever from './StaticLever';
import PropTypes from 'prop-types';

const StaticLeverWrapper = ({ levers }) => {
  return (
    <div>
      {levers.map((lever) => (
        <StaticLever key={lever.title} lever={lever} />
      ))}
    </div>
  );
};

StaticLeverWrapper.propTypes = {
  levers: PropTypes.arrayOf(
    PropTypes.shape({
      title: PropTypes.string.isRequired,
      description: PropTypes.string.isRequired,
      data_type: PropTypes.string.isRequired,
      value: PropTypes.oneOfType([PropTypes.bool, PropTypes.number]).isRequired,
      unit: PropTypes.string.isRequired,
      is_active: PropTypes.bool.isRequired,
      options: PropTypes.arrayOf(
        PropTypes.shape({
          item: PropTypes.string.isRequired,
          data_type: PropTypes.string.isRequired,
          value: PropTypes.oneOfType([PropTypes.bool, PropTypes.number, PropTypes.string]).isRequired,
          text: PropTypes.string,
          unit: PropTypes.string,
        })
      ),
    })
  ).isRequired,
};

export default StaticLeverWrapper;
