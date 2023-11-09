import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import COPY from '../../../COPY';

const AffinityDays = (props) => {
  const { leverList, leverStore } = props;

  const filteredLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const [selectedOption, setSelectedOption] = useState(null);
  const [affinityLevers, setLever] = useState(filteredLevers);

  const handleRadioChange = (option) => {
    setSelectedOption(option);
  };

  const updateLever = (option, index) => (event) => {
    const levers = affinityLevers.map((lever, i) => {
      if (index === i) {
        const opt = lever.options.map((op) => {
          if (op === option) {
            let errorResult = !(/^\d{0,3}$/).test(event);

            if (errorResult) {
              op.errorMessage = 'Please enter a value less than or equal to 999';
            } else {
              op.errorMessage = null;
            }
            op.value = event;
          }

          return op;
        });

        lever.option = opt;

        return lever;
      }

      return lever;

    });

    setLever(levers);
  };

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '15px', left: '100px' },
    '& .usa-input-error label': { bottom: '24px', left: '115px' }
  });

  const generateFields = (dataType, option, lever, index) => {
    if (dataType === 'number') {
      return (
        <NumberField
          name={option.item}
          label={option.unit}
          isInteger
          disabled={lever.is_disabled}
          value={option.value}
          errorMessage={option.errorMessage}
          onChange={updateLever(option, index)}
        />
      );
    }
    if (dataType === 'text') {
      return (
        <TextField
          name={option.item}
          label={false}
          disabled={lever.is_disabled}
          value={option.value}
          onChange={updateLever(option, index)}
        />
      );
    }

    return null;
  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>Affinity Days</h2>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx(styles.activeLever, lever.is_disabled ? styles.leverDisabled : '')}
          key={`${lever.item}-${index}`}
        >
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
                  <div className={styles.combinedRadioInput}>
                    {generateFields(option.data_type, option, lever, index)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
      <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

AffinityDays.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default AffinityDays;
