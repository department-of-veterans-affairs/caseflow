// client/app/admin/components/CaseflowDistribution/DocketTimeGoals.jsx

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from "./InteractableLevers.module.scss";
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';

const DocketTimeGoals = (props) => {
  const { leverList, leverStore } = props;

  const docketLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const leverNumberDiv = css({
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block', position: 'relative'},
    '& .cf-form-int-input .input-container' : {width: 'auto', display: 'inline-block', verticalAlign: 'middle'},
    '& .cf-form-int-input label' : {position: 'absolute',bottom: '8px', left: '75px'},
    '& .usa-input-error label': {bottom: '15px', left: '89px'}
  });

  const [_, setLever] = useState(docketLevers);
  const updateLever = (index) => (e) => {
    const levers = docketLevers.map((lever, i) => {
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

  const toggleLever = (index) => () => {
    const levers = docketLevers.map((lever, i) => {
      if (index === i) {
        lever.is_active = !lever.is_active
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
      <div className={styles.leverH2}>AMA Non-priority Distribution Goals by Docket​</div>
        <p><strong>Docket Time Goals</strong> set the completion target for AMA non-priority appeals by docket type. It represents the number of calendar days that are added to the receipt date of the appeal to establish the decision target date.</p>
        <p><strong>Start Distribution Prior to Goals</strong> days sets the number of calendar days prior to the Docket Time Goal for that docket type when appeals become eligible for distribution.</p>
        <p>Please note, if turned on, non-priority appeals of that docket type will not be distributed until eligible, which may disrupt strict docket-date-order distribution across dockets.​​</p>
        <div className={cx(styles.leverLeft, styles.docketLeverLeft)}><strong></strong></div>
        <div className={styles.leverMiddle}><strong>Docket Time Goal</strong></div>
        <div className={styles.leverRight}><strong>Start Distribution Prior to Docket Time Goal</strong></div>
      </div>
      {docketLevers && docketLevers.map((lever, index) => (
        <div className={cx(styles.activeLever, lever.is_disable ? styles.leverDisabled : '')} key={`${lever.item}-${index}`}>
          <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
            <strong>{lever.title}</strong>
          </div>
          <div className={`${styles.leverMiddle} ${leverNumberDiv}`}>
            <NumberField
              name={lever.item}
              isInteger
              readOnly={true}
              value={lever.value}
              label={lever.unit}
              onChange={updateLever(index)}
            />
          </div>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <ToggleSwitch
              selected={lever.is_active}
              disabled={lever.is_disable}
              toggleSelected={toggleLever(index)}
            />
            <div className={lever.is_active ? styles.toggleSwichInput : styles.toggleInputHide}>
              <NumberField
                name={`toogle-${lever.item}`}
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
      ))}
    </div>

  );
};

DocketTimeGoals.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any
};

export default DocketTimeGoals;
