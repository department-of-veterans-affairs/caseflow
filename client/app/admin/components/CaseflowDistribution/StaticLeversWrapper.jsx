import React from 'react';
import PropTypes from 'prop-types';
import { createStore } from 'redux';
import StaticLever from './StaticLever';
import leversReducer from 'app/admin/reducers/Levers/leversReducer';
import { levers } from 'test/data/adminCaseDistributionLevers';

const activeLevers = levers.filter((lever) => lever.is_active);

const preloadedState = {
  levers: JSON.parse(JSON.stringify(activeLevers)),
  initial_levers: JSON.parse(JSON.stringify(activeLevers))
};

const leverStore = createStore(leversReducer, preloadedState);

const StaticLeverWrapper = () => {
  return (
    <div>
      {leverStore.getState().levers.map((lever) => (
        <StaticLever key={lever.item} lever={lever} />
      ))}
    </div>
  );
};

StaticLeverWrapper.propTypes = {
  levers: PropTypes.arrayOf(
    PropTypes.shape({
      item: PropTypes.string.isRequired,
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
