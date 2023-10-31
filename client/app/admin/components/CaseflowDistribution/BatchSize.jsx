// client/app/admin/components/CaseflowDistribution/BatchSize.jsx

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from "./InteractableLevers.module.scss";
import NumberField from 'app/components/NumberField';

const BatchSize = ({ batchSizeLevers }) => {

  const leverNumberDiv = css({
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block'},
    '& .cf-form-int-input .input-container' : {width: 'auto', display: 'inline-block', verticalAlign: 'middle'},
    '& .cf-form-int-input label' : {float: 'right', margin: '0', lineHeight: '50px'}
  });

  const [lever, setLever] = useState(batchSizeLevers);
  const updateLever = (index) => (e) => {
    const levers = batchSizeLevers.map((lever, i) => {
      if (index === i) {
        lever.value = e;
        return lever;
      } else {
        return lever;
      }
    });
    setLever(levers);
  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
      <div className={styles.leverH2}>Batch Size</div>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {batchSizeLevers && batchSizeLevers.map((lever, index) => (
        <div className={styles.activeLever} key={`${lever.item}-${index}`}>
          <div className={styles.leverLeft}>
            <strong>{lever.title}</strong>
            <p>{lever.description}</p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
            <NumberField
              name={lever.item}
              label={lever.unit}
              isInteger
              value={lever.value}
              onChange={updateLever(index)}
            />
          </div>
        </div>
      ))}
    </div>

  );
};

BatchSize.propTypes = {
    batchSizeLevers: PropTypes.array.isRequired
};

export default BatchSize;
