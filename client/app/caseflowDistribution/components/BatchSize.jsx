import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import styles from "./InteractableLevers.module.scss";
import NumberField from 'app/components/NumberField';

const BatchSize = (props) => {
  const { leverList, leverStore } = props;

  const filteredLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const footerStyling = css({
    marginTop: '10px',
    paddingTop: '10px',
  });

  const leverNumberDiv = css({
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block', position: 'relative'},
    '& .cf-form-int-input .input-container' : {width: 'auto', display: 'inline-block', verticalAlign: 'middle'},
    '& .cf-form-int-input label' : {position: 'absolute',bottom: '8px', left: '75px'},
    '& .usa-input-error label': {bottom: '15px', left: '89px'}
  });

  const [batchSizeLevers, setLever] = useState(filteredLevers);
  const updateLever = (index) => (e) => {
    const levers = batchSizeLevers.map((lever, i) => {
      if (index === i) {
        if (!/^\d{0,3}$/.test(e)) {
          lever.errorMessage = 'Please enter a value less than or equal to 999';
        } else {
          lever.errorMessage = null;
        }
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
              errorMessage={lever.errorMessage}
              onChange={updateLever(index)}
            />
          </div>
        </div>
      ))}
      <h4 {...footerStyling}>* Denotes a variable that is also relevant to the currently inactive distribution algorithm</h4>
      <div className="cf-help-divider"></div>
    </div>

  );
};

BatchSize.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default BatchSize;
