import React from 'react';
import InteractableLeversWrapper from './InteractableLeversWrapper';
import { levers } from 'test/data/adminCaseDistributionLevers';
import styles from './InteractableLevers.module.scss';


export default {
  title: 'Admin/Caseflow Distribution/InteractableLevers',
  component: InteractableLeversWrapper
};

export const ActiveDataElements = (args) => (
  <div>
    <div className={styles.leverTop}>
      <strong>Case Distribution Algorithm Values</strong>
      <p>The Case Distribution Algorithm determines how cases are assigned to VLJs and their teams. Current algorithm is “By Docket Date.”</p>
    </div>
    <InteractableLeversWrapper levers={levers} />
  </div>
);
