import React from 'react';
import PropTypes from 'prop-types';
import StaticLever from './StaticLever';
import COPY from '../../../COPY';

const StaticLeversWrapper = (props) => {
  const { leverList, leverStore } = props;

  const orderedLeversList = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const WrapperList = orderedLeversList.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (

    <table className="table-styling">
      <tbody>
        <tr>
          <th className="table-header-styling-left">{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_LEFT_TITLE}</th>
          <th className="table-header-styling-right">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_VALUES}</th>
        </tr>
      </tbody>
      {WrapperList}
    </table>
  );

};

StaticLeversWrapper.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default StaticLeversWrapper;
