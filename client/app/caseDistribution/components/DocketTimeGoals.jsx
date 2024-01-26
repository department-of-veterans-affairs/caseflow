import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import cx from 'classnames';
import { updateNumberLever, addLeverErrors, removeLeverErrors } from '../reducers/levers/leversActions';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';
import { Constant, sectionTitles, docketTimeGoalPriorMappings } from '../constants';
import { getLeversByGroup, getLeverErrors, getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { validateLeverInput } from '../utils';

const DocketTimeGoals = () => {

  const dispatch = useDispatch();
  const theState = useSelector((state) => state);

  // pull docket time goal and distribution levers from the store
  const currentTimeLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.docket_time_goal);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  const leverErrors = (leverItem) => {
    return getLeverErrors(theState, leverItem);
  };

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
    const validationErrors = validateLeverInput(lever, value);
    const errorExists = leverErrors(leverItem).length > 0;

    if (validationErrors.length > 0 && !errorExists) {
      dispatch(addLeverErrors(validationErrors));
    }

    if (validationErrors.length === 0 && errorExists) {
      dispatch(removeLeverErrors(leverItem));
    }

  };

  const updateNumberFieldLever = (lever) => (event) => {
    // eslint-disable-next-line camelcase
    const { lever_group, item } = lever;

    handleValidation(lever, item, event);
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
    const sectionTitle = sectionTitles[distributionPriorLever.item];

    if (isUserAcdAdmin) {

      return (

        <div id={`${docketTimeGoalLever.item}-lever`}
          className={cx('active-lever')}
          key={`${distributionPriorLever.item}-${index}`}
        >
          <div className={cx('lever-left', 'docket-lever-left')}>
            <strong className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : ''}>
              {sectionTitle || ''}
            </strong>
          </div>
          <div className={`lever-middle docket-time-lever-num-sec
            ${docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}}`}>
            <NumberField
              name={docketTimeGoalLever.item}
              isInteger
              readOnly={docketTimeGoalLever.is_disabled_in_ui}
              value={docketTimeGoalLever.value}
              label={docketTimeGoalLever.unit}
              errorMessage={leverErrors(docketTimeGoalLever.item)}
              onChange={updateNumberFieldLever(docketTimeGoalLever)}
              disabled={docketTimeGoalLever.is_disabled_in_ui}
            />
          </div>
          <div
            className={cx('lever-right', 'docket-lever-right', 'docket-time-lever-num-sec')}
            aria-label={docketTimeGoalLever.title}
            id={`${docketTimeGoalLever.item}-lever-middle`}
          >
            <ToggleSwitch
              id={`toggle-switch-${distributionPriorLever.item}`}
              selected={distributionPriorLever.is_toggle_active}
              disabled={distributionPriorLever.is_disabled_in_ui}
              toggleSelected={toggleLever(index)}
            />
            <div
              className={distributionPriorLever.is_toggle_active ? 'toggle-switch-input' : 'toggle-input-hide'}
            >

              <NumberField
                name={`toggle-${distributionPriorLever.item}`}
                isInteger
                readOnly={distributionPriorLever.is_disabled_in_ui}
                value={distributionPriorLever.value}
                label={distributionPriorLever.unit}
                errorMessage={leverErrors(distributionPriorLever.item)}
                onChange={updateNumberFieldLever(distributionPriorLever)}
                disabled={distributionPriorLever.is_disabled_in_ui}
              />
            </div>
          </div>
        </div>

      );
    }

    return (

      <div className="active-lever"
        key={`${distributionPriorLever.item}-${index}`}
        id={`${distributionPriorLever.item}-lever-section`}
      >
        <div className={cx('lever-left', 'docket-lever-left')}>
          <strong className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : ''}>
            { sectionTitle || '' }
          </strong>
        </div>
        <div className={cx('lever-middle', 'docket-time-lever-num-sec')}
          id={`${distributionPriorLever.item}-lever-value`}
        >
          <span className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}
            data-disabled-in-ui={docketTimeGoalLever.is_disabled_in_ui}
          >
            {docketTimeGoalLever.value} {docketTimeGoalLever.unit}
          </span>
        </div>
        <div className={cx('lever-right', 'docket-lever-right', 'docket-time-lever-num-sec')}
          id={`${distributionPriorLever.item}-lever-toggle`}
        >
          <div className={cx('lever-right', 'docket-lever-right', 'docket-time-lever-num-sec')}>
            <span className={distributionPriorLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}
              data-disabled-in-ui={distributionPriorLever.is_disabled_in_ui}
            >
              {distributionPriorLever.is_toggle_active ? 'On' : 'Off'}
            </span>
          </div>
        </div>
      </div>
    );

  };

  return (
    <div className="lever-content">
      <div className="lever-head">
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
        <div className="docker-lever-table">
          <div className={cx('lever-left', 'docket-lever-left')}><strong></strong></div>
          <div className="lever-middle"><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_LEFT}</strong></div>
          <div className="lever-right"><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_RIGHT}</strong></div>
        </div>
      </div>

      {docketDistributionLevers?.
        toSorted((leverA, leverB) => leverA.lever_group_order - leverB.lever_group_order).
        map((distributionPriorLever, index) => (renderDocketDistributionLever(distributionPriorLever, index)))
      }
    </div>

  );
};

export default DocketTimeGoals;
