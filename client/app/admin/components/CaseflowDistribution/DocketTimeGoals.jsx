// client/app/admin/components/CaseflowDistribution/DocketTimeGoals.jsx

import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css, style } from 'glamor';
import cx from 'classnames';
import styles from "./InteractableLevers.module.scss";
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';

const DocketTimeGoals = ({ docketLevers }) => {

  const leverNumberDiv = css({
    '& .cf-form-int-input' : {width: 'auto', display: 'inline-block'}
  });

  const [lever, setLever] = useState(docketLevers);
  const updateLever = (index) => (e) => {
    const levers = docketLevers.map((lever, i) => {
      if (index === i) {
        lever.value = e;

        return lever;
      } else {
        return lever;
      }
    });
    setLever(levers);
  };

  const toggleLever = (index) => (e) => {
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

  const [selected, setSelected] = useState(false);

  const handleChange = (lever) => {
    setSelected(!selected)
  }

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h3>AMA Non-priority Distribution Goals by Docket​</h3>
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
              readOnly={!lever.is_active}
              value={lever.value}
              label={false}
              onChange={updateLever(index)}
            />
            <span className={styles.leverUnit}>{lever.unit}</span>
          </div>
          <div className={`${styles.leverRight} ${styles.docketLeverRight}`}>
            <ToggleSwitch
              selected={lever.is_active}
              disabled={lever.is_disable}
              toggleSelected={toggleLever(index)}
            />
          </div>
        </div>
      ))}
    </div>

  );
};

DocketTimeGoals.propTypes = {
    docketLevers: PropTypes.array.isRequired
};

export default DocketTimeGoals;
