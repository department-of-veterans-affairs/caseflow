// client/app/admin/components/CaseflowDistribution/AffinityDays.jsx

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from "./InteractableLevers.module.scss";
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';

const AffinityDays = (props) => {
  const { leverList, leverStore } = props;

  const affinityLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const [selectedOption, setSelectedOption] = useState(null);
  const [_, setLever] = useState(affinityLevers);

  const handleRadioChange = (option) => {
    setSelectedOption(option);
  };

  const updateLever = (option, index) => (e) => {
    const levers = affinityLevers.map((lever, i) => {
      if (index === i) {
        const opt = lever.options.map((opt) => {
          if (opt === option) {
            if (!/^\d{0,3}$/.test(e)) {
              opt.errorMessage = 'Please enter a value less than or equal to 999';
            } else {
              opt.errorMessage = null;
            }
            opt.value = e;
          }
          return opt;
        })
        lever.option = opt;
        return lever;
      } else {
        return lever;
      }
    });
    setLever(levers);
  };

  const leverNumberDiv = css({
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block', position: 'relative'},
    '& .cf-form-int-input .input-container' : {width: 'auto', display: 'inline-block', verticalAlign: 'middle'},
    '& .cf-form-int-input label' : {position: 'absolute',bottom: '15px', left: '100px'},
    '& .usa-input-error label': {bottom: '24px', left: '115px'}
  });

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <div className={styles.leverH2}>Affinity Days</div>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx(styles.activeLever, lever.is_disable ? styles.leverDisabled : '')}  key={`${lever.item}-${index}`}>
          <div className={styles.leverLeft}>
            <strong>{lever.title}</strong>
            <p>{lever.description}</p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
            {lever.options.map((option) => (
              <div>
                <div>
                  <input
                    type="radio"
                    value={option.item}
                    disabled={lever.is_disable}
                    id={`${lever.item}-${option.item}`}
                    name={lever.item}
                    onChange={() => handleRadioChange(option)}
                  />
                  <label htmlFor={`${lever.item}-${option.item}`}>
                    {option.text}
                  </label>
                </div>

                <div>
                {selectedOption === option && (
                  <div className={styles.combinedRadioInput}>
                    {option.data_type === 'number' ? (
                      <NumberField
                        name={option.item}
                        label={option.unit}
                        isInteger
                        disabled={lever.is_disable}
                        value={option.value}
                        errorMessage={option.errorMessage}
                        onChange={updateLever(option,index)}
                      />
                    ) : (
                      option.data_type === 'text' ? (
                        <TextField
                          name={option.item}
                          label={false}
                          disabled={lever.is_disable}
                          value={option.value}
                          onChange={updateLever(option,index)}
                        />
                      ) : null
                    )}
                  </div>
                )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
  }


AffinityDays.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default AffinityDays;
