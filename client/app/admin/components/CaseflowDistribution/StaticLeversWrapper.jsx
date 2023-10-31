import React from 'react';
import PropTypes from 'prop-types';

import StaticLever from './StaticLever';

const StaticLeversWrapper = (props) => {
  const { leverList, leverStore } = props;

  const orderedLeversList = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const WrapperList = orderedLeversList.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (
    <div>{WrapperList}</div>
  );

};

StaticLeversWrapper.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default StaticLeversWrapper;
