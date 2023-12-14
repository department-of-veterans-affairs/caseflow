import React, { useState } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
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

  const [affinityLevers, setAffinityLevers] = useState(filteredLevers);

  const updateLever = (option, index, value) => {
    const updatedLevers = affinityLevers.map((l, i) => {
      if (index === i) {
        const updatedOptions = l.options.map((op) => {
          if (op === option) {
            let errorResult = !(/^\d{0,3}$/).test(value);

            if (errorResult) {
              op.errorMessage = 'Please enter a value less than or equal to 999';
              op.value = null;
            } else {
              op.errorMessage = null;
              op.value = value;
            }
          }

          return op;
        });

        return { ...l, options: updatedOptions };

      }

      return l;
    });

    setAffinityLevers(updatedLevers);

    leverStore.dispatch({
      type: Constants.UPDATE_LEVER_VALUE,
      updated_lever: { item: option.item, value: option.value }
    });
  };

  const handleRadioChange = (lever, option) => {
    if (lever && option) {
      const updatedLevers = affinityLevers.map((l) => {
        if (l.item === lever.item) {
          return { ...l, value: option.item };
        }

        return l;
      });

      setAffinityLevers(updatedLevers);

      leverStore.dispatch({
        type: Constants.UPDATE_LEVER_VALUE,
        updated_lever: { item: lever.item, value: option.item }
      });
    }
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
          readOnly={lever.is_disabled}
          value={option.value}
          errorMessage={option.errorMessage}
          onChange={(value) => updateLever(lever, option, index, value)}
        />
      );
    }
    if (dataType === 'text') {
      return (
        <TextField
          name={option.item}
          label={false}
          readOnly={lever.is_disabled}
          value={option.value}
          onChange={(value) => updateLever(lever, option, index, value)}
        />
      );
    }

    return null;
  };

  const generateMemberViewLabel = (option, lever) => {

    if (lever.value === option.item) {
      return (
        <div>
          <div>
            <label className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}
              htmlFor={`${lever.item}-${option.item}`}>
              {option.text} {option.value} {option.unit}
            </label>
          </div>
        </div>
      );
    }

    return null;
  };

  let isMemberUser = !props.isAdmin;

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

              (isMemberUser) ?
                generateMemberViewLabel(option, lever) :
                <div key={`${lever.item}-${index}-${option.item}`}>
                  <div>
                    <input
                      checked={option.item === lever.value}
                      type="radio"
                      value={option.item}
                      disabled={lever.is_disabled}
                      id={`${lever.item}-${option.item}`}
                      name={lever.item}
                      onChange={() => handleRadioChange(lever, option, index)}
                    />
                    <label htmlFor={`${lever.item}-${option.item}`}>
                      {option.text}
                    </label>
                  </div>

                  <div>
                    <div className={styles.combinedRadioInput}>
                      {generateFields(option.data_type, option, lever, isMemberUser, index)}
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
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
};

export default AffinityDays;

