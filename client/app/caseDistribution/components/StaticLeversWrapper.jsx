import React from 'react';
import { useSelector } from 'react-redux';
import StaticLever from './StaticLever';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/StaticLevers.module.scss';
import { Constant } from '../constants';
import { getLeversByGroup } from '../reducers/levers/leversSelector';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const StaticLeversWrapper = () => {

  const theState = useSelector((state) => state);

  const currentStaticLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.static);

  const WrapperList = currentStaticLevers.map((lever) => (
    <StaticLever key={lever.item} lever={lever} />
  ));

  return (

    <table className={styles.tableStyling}>
      <tbody>
        <tr>
          <th className={styles.tableHeaderStylingLeft}>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_LEFT_TITLE}</th>
          <th className={styles.tableHeaderStylingRight}>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_VALUES}</th>
        </tr>
      </tbody>
      {WrapperList}
    </table>
  );

};

export default StaticLeversWrapper;
