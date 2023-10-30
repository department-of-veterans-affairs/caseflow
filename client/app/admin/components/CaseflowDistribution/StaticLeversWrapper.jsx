import React from 'react';
import PropTypes from 'prop-types';
// import { createStore } from 'redux';
import StaticLever from './StaticLever';
// import leversReducer from 'app/admin/reducers/Levers/leversReducer';
import { levers } from 'test/data/adminCaseDistributionLevers';

// const activeLevers = levers.filter((lever) => lever.is_active);

// const preloadedState = {
//   levers: JSON.parse(JSON.stringify(activeLevers)),
//   initial_levers: JSON.parse(JSON.stringify(activeLevers))
// };

// {levers.map((lever) => (
//   <StaticLever key={lever.item} lever={lever} />
// ))}
// const leverStore = createStore(leversReducer, preloadedState);
const StaticLeversWrapper = (props) => {
  const { leverList } = props;

  const orderedLeversList = leverList.map((item) => {
    return levers.find((lever) => lever.item === item);
  });

  const WrapperList = orderedLeversList.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (
    <div>{WrapperList}</div>
  );

};

StaticLeversWrapper.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired };

export default StaticLeversWrapper;
