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
  const footerStyling = css({
    marginTop: '10px',
    paddingTop: '10px',
  });

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
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block'}
  });

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <div className={styles.leverH2}>Affinity Days</div>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx(styles.activeLever, lever.is_disabled ? styles.leverDisabled : '')}  key={`${lever.item}-${index}`}>
          <div className={styles.leverLeft}>
            <strong>{lever.title}</strong>
            <p>{lever.description}</p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
            {lever.options.map((option) => (
              <div>
                <div>
                  <input
                    checked={selectedOption ? option.item === selectedOption.item : option.item === lever.value}
                    type="radio"
                    value={option.item}
                    disabled={lever.is_disabled}
                    id={`${lever.item}-${option.item}`}
                    name={lever.item}
                    onChange={() => handleRadioChange(option)}
                  />
                  <label htmlFor={`${lever.item}-${option.item}`}>
                    {option.text}
                  </label>
                </div>

                <div>
                {(
                  <div className={styles.combinedRadioInput}>
                    {option.data_type === 'number' ? (
                      <NumberField
                        name={option.item}
                        label={false}
                        isInteger
                        disabled={lever.is_disabled}
                        value={option.value}
                        onChange={updateLever(option,index)}
                      />
                    ) : (
                      option.data_type === 'text' ? (
                        <TextField
                          name={option.item}
                          label={false}
                          disabled={lever.is_disabled}
                          value={option.value}
                          onChange={updateLever(option,index)}
                        />
                      ) : null
                    )}
                    {option.unit && <span className={styles.leverUnit}>{option.unit}</span>}
                  </div>
                )}
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
      <h4 {...footerStyling}>* Denotes a variable that is also relevant to the currently inactive distribution algorithm</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
  }


AffinityDays.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default AffinityDays;
