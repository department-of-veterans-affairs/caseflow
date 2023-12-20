import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';
import leverInputValidation from './LeverInputValidation';
import COPY from '../../../COPY';

const DocketTimeGoals = (props) => {
  const { leverList, leverStore } = props;

  const filteredDistributionLevers = leverList.docketDistributionPriorLevers.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });
  const filteredTimeGoalLevers = leverList.docketTimeGoalLevers.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });
  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const errorMessages = {};

  const [docketDistributionLevers, setDistributionLever] = useState(filteredDistributionLevers);
  const [docketTimeGoalLevers, setTimeGoalLever] = useState(filteredTimeGoalLevers);
  const [errorMessagesList, setErrorMessages] = useState(errorMessages);

  const updateLever = (index, leverType) => (event) => {
    if (leverType === 'DistributionPrior') {

      const levers = docketDistributionLevers.map((lever, i) => {
        if (index === i) {

          let validationResponse = leverInputValidation(lever, event, errorMessagesList);

          if (validationResponse.statement === 'SUCCESS') {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);
            leverStore.dispatch({
              type: Constants.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              validChange: true
            });

            return lever;
          }
          if (validationResponse.statement === 'FAIL') {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);

            leverStore.dispatch({
              type: Constants.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              validChange: false
            });

            return lever;
          }
        }

        return lever;
      });

      setDistributionLever(levers);
    }
    if (leverType === 'TimeGoal') {
      const levers = docketTimeGoalLevers.map((lever, i) => {
        if (index === i) {

          let validationResponse = leverInputValidation(lever, event, errorMessagesList);

          if (validationResponse.statement === 'SUCCESS') {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);
            leverStore.dispatch({
              type: Constants.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              validChange: true
            });

            return lever;
          }
          if (validationResponse.statement === 'FAIL') {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);
            leverStore.dispatch({
              type: Constants.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              validChange: false
            });

            return lever;
          }
        }

        return lever;
      });

      setTimeGoalLever(levers);
    }
  };

  const toggleLever = (index) => () => {
    const levers = docketDistributionLevers.map((lever, i) => {
      if (index === i) {
        lever.is_active = !lever.is_active;

        return lever;
      }

      return lever;

    });

    setDistributionLever(levers);
  };

  const generateToggleSwitch = (distributionPriorLever, index, isAdmin) => {

    let docketTimeGoalLever = '';

    if (index < docketTimeGoalLevers.length) {
      docketTimeGoalLever = docketTimeGoalLevers[index];
    }

    if (isAdmin) {

      return (

        <div className={cx(styles.activeLever)}
          key={`${distributionPriorLever.item}-${index}`}
        >
          <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
            <strong className={docketTimeGoalLever.is_disabled ? styles.leverDisabled : ''}>
              {index < props.sectionTitles.length ? props.sectionTitles[index] : ''}
            </strong>
          </div>
          <div className={`${styles.leverMiddle} ${leverNumberDiv}
            ${docketTimeGoalLever.is_disabled ? styles.leverDisabled : styles.leverActive}}`}>
            <NumberField
              name={docketTimeGoalLever.item}
              isInteger
              readOnly={docketTimeGoalLever.is_disabled}
              value={docketTimeGoalLever.value}
              label={docketTimeGoalLever.unit}
              errorMessage={errorMessagesList[docketTimeGoalLever.item]}
              onChange={updateLever(index, 'TimeGoal')}
            />
          </div>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <ToggleSwitch
              id={`toggle-switch-${distributionPriorLever.item}`}
              selected={distributionPriorLever.is_active}
              disabled={distributionPriorLever.is_disabled}
              toggleSelected={toggleLever(index)}
            />
            <div className={distributionPriorLever.is_active ? styles.toggleSwitchInput : styles.toggleInputHide}>

              <NumberField
                name={`toggle-${distributionPriorLever.item}`}
                isInteger
                readOnly={distributionPriorLever.is_disabled}
                value={distributionPriorLever.value}
                label={distributionPriorLever.unit}
                errorMessage={errorMessagesList[distributionPriorLever.item]}
                onChange={updateLever(index, 'DistributionPrior')}
              />
            </div>
          </div>
        </div>

      );
    }

    return (

      <div className={cx(styles.activeLever)}
        key={`${distributionPriorLever.item}-${index}`}
      >
        <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
          <strong className={docketTimeGoalLever.is_disabled ? styles.leverDisabled : ''}>
            {index < props.sectionTitles.length ? props.sectionTitles[index] : ''}
          </strong>
        </div>
        <div className={`${styles.leverMiddle} ${leverNumberDiv}`}>
          <span className={docketTimeGoalLever.is_disabled ? styles.leverDisabled : styles.leverActive}>
            {docketTimeGoalLever.value} {docketTimeGoalLever.unit}
          </span>
        </div>
        <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <span className={distributionPriorLever.is_disabled ? styles.leverDisabled : styles.leverActive}>
              {distributionPriorLever.is_active ? 'On' : 'Off'}
            </span>
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

      {docketDistributionLevers && docketDistributionLevers.map((distributionPriorLever, index) => (

        props.isAdmin ? generateToggleSwitch(distributionPriorLever, index, true) :
          generateToggleSwitch(distributionPriorLever, index, false)
      ))}
    </div>

  );
};

DocketTimeGoals.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
  sectionTitles: PropTypes.array.isRequired
};

export default DocketTimeGoals;
