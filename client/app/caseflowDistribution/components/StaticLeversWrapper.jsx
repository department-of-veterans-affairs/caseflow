import React from 'react';
import PropTypes from 'prop-types';
import StaticLever from './StaticLever';
import styles from 'app/styles/caseDistribution/StaticLevers.module.scss';

const StaticLeversWrapper = (props) => {
  const { leverList, leverStore } = props;

  const orderedLeversList = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const WrapperList = orderedLeversList.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (

    <table className={styles.tableStyling}>
      <tbody>
        <tr>
          <th className={styles.tableHeaderStyling}>Data Elements</th>
          <th className={styles.tableHeaderStyling}>Values</th>
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
