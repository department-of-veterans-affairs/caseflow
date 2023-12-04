import React, { useState } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import { css } from 'glamor';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';


const BatchSize = (props) => {
  const { leverList, leverStore } = props;

  const filteredLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const [batchSizeLevers, setLever] = useState(filteredLevers);
  const updateLever = (index, changedItem) => (event) => {
    const lever = batchSizeLevers.find((lever) => lever.item === changedItem);
    leverStore.dispatch({
      type: Constants.UPDATE_LEVER_VALUE,
      updated_lever: { item: changedItem, value: event }
    })

    const levers = batchSizeLevers.map((lever, i) => {
      if (index === i) {
        let errorResult = !(/^\d{0,3}$/).test(event);

        if (errorResult) {
          lever.errorMessage = 'Please enter a value less than or equal to 999';
        } else {
          lever.errorMessage = null;
        }
        lever.value = event;

        return lever;
      }

      return lever;
    });

    setLever(levers);
  };

  let isMemberUser = !props.isAdmin;

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>Batch Size</h2>
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
            {isMemberUser ?

              <label className={`${styles.disabledText}`}>
                {lever.value} {lever.unit}
              </label> :
              <NumberField
                name={lever.item}
                label={lever.unit}
                isInteger
                readOnly={lever.is_disabled}
                value={lever.value}
                errorMessage={lever.errorMessage}
                onChange={updateLever(index, lever.item, lever.item)}
              />
}
          </div>
        </div>
      ))}
      <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

BatchSize.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
};

export default BatchSize;
