import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import cx from 'classnames';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import { updateNumberLever, addLeverErrors, removeLeverErrors } from '../reducers/levers/leversActions';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';
import { Constant, sectionTitles, docketTimeGoalPriorMappings } from '../constants';
import { getLeversByGroup, getLeverErrors, getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { validateLeverInput } from '../utils';

const DocketTimeGoals = () => {

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const dispatch = useDispatch();
  const theState = useSelector((state) => state);

  // pull docket time goal and distribution levers from the store
  const currentTimeLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.docket_time_goal);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  function leverErrors(leverItem) {
    return getLeverErrors(theState, leverItem)
  }

  const currentDistributionPriorLevers =
    getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.docket_distribution_prior);

  const [docketDistributionLevers, setDistributionLever] = useState(currentDistributionPriorLevers);
  const [docketTimeGoalLevers, setTimeGoalLever] = useState(currentTimeLevers);

  useEffect(() => {
    setDistributionLever(currentDistributionPriorLevers);
  }, [currentDistributionPriorLevers]);

  useEffect(() => {
    setTimeGoalLever(currentTimeLevers);
  }, [currentTimeLevers]);

  const handleValidation = (lever, leverItem, value) => {
    const validationErrors = validateLeverInput(lever, value)
    const errorExists = leverErrors(leverItem).length > 0
    if(validationErrors.length > 0 && !errorExists) {
      dispatch(addLeverErrors(validationErrors))
    }

    if (validationErrors.length === 0 && errorExists) {
      dispatch(removeLeverErrors(leverItem))
    }

  }

  const updateNumberFieldLever = (lever) => (event) => {
    const { lever_group, item } = lever
    handleValidation(lever, item, event)
    dispatch(updateNumberLever(lever_group, item, event));
  };

  const toggleLever = (index) => () => {
    const levers = docketDistributionLevers.map((lever, i) => {
      if (index === i) {
        lever.is_toggle_active = !lever.is_toggle_active;

        return lever;
      }

      return lever;

    });

    setDistributionLever(levers);
  };

  const renderDocketDistributionLever = (distributionPriorLever, index) => {
    let docketTimeGoalLever = docketTimeGoalLevers.find((lever) =>
      lever.item === docketTimeGoalPriorMappings[distributionPriorLever.item]);

    if (isUserAcdAdmin) {

      const sectionTitle = sectionTitles[distributionPriorLever.item];

      return (

        <div className={cx(styles.activeLever)}
          key={`${distributionPriorLever.item}-${index}`}
        >
          <div className={cx(styles.leverLeft, styles.docketLeverLeft)}>
            <strong className={docketTimeGoalLever.is_disabled_in_ui ? styles.leverDisabled : ''}>
              {sectionTitle || ''}
            </strong>
          </div>
          <div className={`${styles.leverMiddle} ${leverNumberDiv}
            ${docketTimeGoalLever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}}`}>
            <NumberField
              name={docketTimeGoalLever.item}
              isInteger
              readOnly={docketTimeGoalLever.is_disabled_in_ui}
              value={docketTimeGoalLever.value}
              label={docketTimeGoalLever.unit}
              errorMessage={leverErrors(docketTimeGoalLever.item)}
              onChange={updateNumberFieldLever(docketTimeGoalLever)}
            />
          </div>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <ToggleSwitch
              id={`toggle-switch-${distributionPriorLever.item}`}
              selected={distributionPriorLever.is_toggle_active}
              disabled={distributionPriorLever.is_disabled_in_ui}
              toggleSelected={toggleLever(index)}
            />
            <div
              className={distributionPriorLever.is_toggle_active ? styles.toggleSwitchInput : styles.toggleInputHide}
            >

              <NumberField
                name={`toggle-${distributionPriorLever.item}`}
                isInteger
                readOnly={distributionPriorLever.is_disabled_in_ui}
                value={distributionPriorLever.value}
                label={distributionPriorLever.unit}
                errorMessage={leverErrors(distributionPriorLever.item)}
                onChange={updateNumberFieldLever(distributionPriorLever)}
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
          <strong className={docketTimeGoalLever.is_disabled_in_ui ? styles.leverDisabled : ''}>
            {index < sectionTitles.length ? sectionTitles[index] : ''}
          </strong>
        </div>
        <div className={`${styles.leverMiddle} ${leverNumberDiv}`}>
          <span className={docketTimeGoalLever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}>
            {docketTimeGoalLever.value} {docketTimeGoalLever.unit}
          </span>
        </div>
        <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
          <div className={`${styles.leverRight} ${styles.docketLeverRight} ${leverNumberDiv}`}>
            <span className={distributionPriorLever.is_disabled_in_ui ? styles.leverDisabled : styles.leverActive}>
              {distributionPriorLever.is_toggle_active ? 'On' : 'Off'}
            </span>
          </div>
        </div>
      </div>
    );

  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_SECTION_TITLE}</h2>
        <p className="cf-lead-paragraph">
          <strong className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_LEFT}</strong>
          {COPY.CASE_DISTRIBUTION_DOCKET_TIME_DESCRIPTION_LEFT}
        </p>
        <p className="cf-lead-paragraph">
          <strong className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_RIGHT}</strong>
          {COPY.CASE_DISTRIBUTION_DOCKET_TIME_DESCRIPTION_RIGHT}
        </p>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_DOCKET_TIME_NOTE}</p>
        <div className={cx(styles.leverLeft, styles.docketLeverLeft)}><strong></strong></div>
        <div className={styles.leverMiddle}><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_LEFT}</strong></div>
        <div className={styles.leverRight}><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_RIGHT}</strong></div>
      </div>

      {docketDistributionLevers?.
        toSorted((leverA, leverB) => leverA.lever_group_order - leverB.lever_group_order).
        map((distributionPriorLever, index) => (renderDocketDistributionLever(distributionPriorLever, index)))
      }
    </div>

  );
};

export default DocketTimeGoals;
