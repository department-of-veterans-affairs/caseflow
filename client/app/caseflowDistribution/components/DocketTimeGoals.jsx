import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';

const DocketTimeGoals = (props) => {
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

  const [docketLevers, setLever] = useState(filteredLevers);
  const updateLever = (index) => (event) => {
    const levers = docketLevers.map((lever, i) => {
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

  const toggleLever = (index) => () => {
    const levers = docketLevers.map((lever, i) => {
      if (index === i) {
        lever.is_active = !lever.is_active;

        return lever;
      }

      return lever;

    });

    setLever(levers);
  };

  const generateToggleSwitch = (lever, index, toggleOn) => {

    if (toggleOn) {
      return (

        <div className={cx(styles.activeLever, lever.is_disabled ? styles.leverDisabled : '')}
          key={`${lever.item}-${index}`}
        >
          <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
            <strong>{lever.title}</strong>
          </div>
          <div className={`${styles.leverMiddle} ${leverNumberDiv}`}>
            <NumberField
              name={lever.item}
              isInteger
              readOnly
              value={lever.value}
              label={lever.unit}
              onChange={updateLever(index)}
            />
          </div>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <ToggleSwitch
              id={`toggle-switch-${lever.item}`}
              selected={lever.is_active}
              disabled={lever.is_disabled}
              toggleSelected={toggleLever(index)}
            />
            <div className={lever.is_active ? styles.toggleSwitchInput : styles.toggleInputHide}>
              <NumberField
                name={`toggle-${lever.item}`}
                isInteger
                readOnly={!lever.is_active}
                value={lever.value}
                label={lever.unit}
                errorMessage={lever.errorMessage}
                onChange={updateLever(index)}
              />
            </div>
          </div>
        </div>

      );
    }

    return (

      <div className={cx(styles.activeLever)}
        key={`${lever.item}-${index}`}
      >
        <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
          <strong className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>{lever.title}</strong>
        </div>
        <div className={`${styles.leverMiddle} ${leverNumberDiv}`}>
          <span className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>{lever.value} {lever.unit}</span>
        </div>
        <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <span className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>Off</span>
          </div>
        </div>
      </div>
    );

  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>{COPY.CASE_DISTRIBUTION_DISTRIBUTION_TITLE}</h2>
        <p className="cf-lead-paragraph">
          <strong className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_1}</strong>
          {COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_2}
        </p>
        <p className="cf-lead-paragraph">
          <strong className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DISTRIBUTION_1}</strong>
          {COPY.CASE_DISTRIBUTION_DISTRIBUTION_2}
        </p>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DOCKET_TIME_NOTE}</p>
        <div className={cx(styles.leverLeft, styles.docketLeverLeft)}><strong></strong></div>
        <div className={styles.leverMiddle}><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_1}</strong></div>
        <div className={styles.leverRight}><strong>{COPY.CASE_DISTRIBUTION_DISTRIBUTION_1}</strong></div>
      </div>
      {docketLevers && docketLevers.map((lever, index) => (
        props.isAdmin ? generateToggleSwitch(lever, index, true) : generateToggleSwitch(lever, index, false)
      ))}
    </div>

  );
};

DocketTimeGoals.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
};

export default DocketTimeGoals;
