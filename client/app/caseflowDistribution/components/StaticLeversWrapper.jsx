import React from 'react';
import PropTypes, { object } from 'prop-types';
import StaticLever from './StaticLever';
import styles from 'app/styles/caseDistribution/StaticLevers.module.scss';

const StaticLeversWrapper = (props) => {
  const { leverList, leverStore, loadedLevers } = props;

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
          <th className={styles.tableHeaderStylingLeft}>Data Elements</th>
          <th className={styles.tableHeaderStylingRight}>Values</th>
        </tr>
      </tbody>
      {WrapperList}
    </table>
  );

};

StaticLeversWrapper.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  loadedLevers: PropTypes.arrayOf(object).isRequired
};

export default StaticLeversWrapper;
