import React from 'react';
import InteractableLevers from './InteractableLevers';

import { Tabs } from 'app/components/tabs/Tabs';
import { Tab } from 'app/components/tabs/Tab';

import InteractableLever from './InteractableLever';
import BatchSize from './BatchSize';
import DocketTimeGoals from './DocketTimeGoals';
import AffinityDays from './AffinityDays';
import { levers } from 'test/data/adminCaseDistributionLevers';
import styles from './InteractableLevers.module.scss';


export default {
  title: 'Admin/Caseflow Distribution/InteractableLevers',
  component: InteractableLevers
};

const batchSizeLevers = levers.filter((lever) => {
  return lever.data_type === "number";
});

const docketLevers = levers.filter((lever) => {
  return lever.data_type === "combination";
});

const affinityLevers = levers.filter((lever) => {
  return lever.data_type === "radio";
});

export const tabs = (args) => (
  <Tabs {...args}>
    <Tab title="Case Distribution" value="1">
      <div className={styles.leverTop}>
        <strong>Case Distribution Algorithm Values</strong>
        <p>The Case Distribution Algorithm determines how cases are assigned to VLJs and their teams. Current algorithm is “By Docket Date.”</p>
      </div>
      <div className={styles.leverContainer}>
        <div className={styles.leverContent}>
          <div className={styles.leverHead}>
          <div className={styles.leverH2}>Active Data Elements</div>
            <p>You may make changes to the Case Distribution algorithm values based on the data elements below. Changes will be applied to the next scheduled case distribution event unless subsequent confirmed changes are made to the same variable.</p>
          </div>
        </div>
        <BatchSize batchSizeLevers={batchSizeLevers} />
        <AffinityDays affinityLevers={affinityLevers} />
        <DocketTimeGoals docketLevers={docketLevers} />
      </div>
    </Tab>
    <Tab title="Veteran Extract" value="2">
      Veteran Extract content
    </Tab>
  </Tabs>
);
