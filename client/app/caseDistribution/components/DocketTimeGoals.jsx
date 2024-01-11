import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import { updateLeverState } from '../reducers/levers/leversActions';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import NumberField from 'app/components/NumberField';
import COPY from '../../../COPY';
import { Constant, sectionTitles } from '../constants';
import { getLeversByGroup } from '../reducers/levers/leversSelector';

const DocketTimeGoals = (props) => {
  const { isAdmin } = props;

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });

  const errorMessages = {};

  const dispatch = useDispatch();
  const theState = useSelector((state) => state);

  // pull docket time goal and distribution levers from the store
  const currentTimeLevers = getLeversByGroup(theState, Constant.LEVERS, Constant.DOCKET_TIME_GOAL);
  const currentDistributionPriorLevers =
    getLeversByGroup(theState, Constant.LEVERS, Constant.DOCKET_DISTRIBUTION_PRIOR);

  const [docketDistributionLevers, setDistributionLever] = useState(currentDistributionPriorLevers);
  const [docketTimeGoalLevers, setTimeGoalLever] = useState(currentTimeLevers);
  const [errorMessagesList] = useState(errorMessages);

  useEffect(() => {
    setDistributionLever(currentDistributionPriorLevers);
  }, [currentDistributionPriorLevers]);

  useEffect(() => {
    setTimeGoalLever(currentTimeLevers);
  }, [currentTimeLevers]);

  const updateLever = (leverItem, leverType, toggleValue = false) => (event) => {
    dispatch(updateLeverState(leverType, leverItem, event, null, toggleValue))
  }

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

  const generateToggleSwitch = (distributionPriorLever, index) => {

    let docketTimeGoalLever = '';

    if (index < docketTimeGoalLevers.length) {
      docketTimeGoalLever = docketTimeGoalLevers[index];
    }

    if (isAdmin) {

      return (

        <div className={cx('active-lever')}
          key={`${distributionPriorLever.item}-${index}`}
        >
          <div className={cx('lever-left', 'docket-lever-left')}>
            <strong className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : ''}>
              {index < sectionTitles.length ? sectionTitles[index] : ''}
            </strong>
          </div>
          <div className={`lever-middle ${leverNumberDiv}
            ${docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}}`}>
            <NumberField
              name={docketTimeGoalLever.item}
              isInteger
              readOnly={docketTimeGoalLever.is_disabled_in_ui}
              value={docketTimeGoalLever.value}
              label={docketTimeGoalLever.unit}
              errorMessage={errorMessagesList[docketTimeGoalLever.item]}
              onChange={updateLever(docketTimeGoalLever.item, Constant.DOCKET_TIME_GOAL)}
            />
          </div>
          <div className={`lever-right docket-lever-right ${leverNumberDiv}`}>
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
                errorMessage={errorMessagesList[distributionPriorLever.item]}
                onChange={updateLever(distributionPriorLever.item, Constant.DOCKET_DISTRIBUTION_PRIOR, true)}
              />
            </div>
          </div>
        </div>

      );
    }

    return (

      <div className={cx('active-lever')}
        key={`${distributionPriorLever.item}-${index}`}
      >
        <div className={cx('lever-left', 'docket-lever-left')}>
          <strong className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : ''}>
            {index < sectionTitles.length ? sectionTitles[index] : ''}
          </strong>
        </div>
        <div className={`'lever-middle' ${leverNumberDiv}`}>
          <span className={docketTimeGoalLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
            {docketTimeGoalLever.value} {docketTimeGoalLever.unit}
          </span>
        </div>
        <div className={`lever-right docket-lever-right ${leverNumberDiv}`}>
          <div className={`lever-right docket-lever-right ${leverNumberDiv}`}>
            <span className={distributionPriorLever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}>
              {distributionPriorLever.is_toggle_active ? 'On' : 'Off'}
            </span>
          </div>
        </div>
      </div>
    );

  };

  return (
    <div className='lever-content'>
      <div className='lever-head'>
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
        <div className={cx('lever-left', 'docket-lever-left')}><strong></strong></div>
        <div className='lever-middle'><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_LEFT}</strong></div>
        <div className='lever-right'><strong>{COPY.CASE_DISTRIBUTION_DOCKET_TIME_GOALS_TITLE_RIGHT}</strong></div>
      </div>

      {docketDistributionLevers && docketDistributionLevers.map((distributionPriorLever, index) => (
        generateToggleSwitch(distributionPriorLever, index)
      ))}
    </div>

  );
};

DocketTimeGoals.propTypes = {
  isAdmin: PropTypes.bool.isRequired,
  sectionTitles: PropTypes.array.isRequired
};

export default DocketTimeGoals;
