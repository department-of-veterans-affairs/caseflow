/* eslint-disable camelcase */
import React, { useState, useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import ExcludeDocketLever from './ExcludeDocketLever';
import { updateLeverValue } from '../reducers/levers/leversActions';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);
  const dispatch = useDispatch();

  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  let docketLevers = theState.caseDistributionLevers?.levers?.docket_levers ?? [];

  docketLevers = docketLevers.sort((leverA, leverB) => leverA.lever_group_order - leverB.lever_group_order);

  const priorityLevers = docketLevers.filter((lever) => lever.control_group === ACD_LEVERS.priority);
  const nonPriorityLevers = docketLevers.filter((lever) => lever.control_group === ACD_LEVERS.non_priority);

  const priorityRadios = priorityLevers.map((lever) => ({
    displayText: lever.title,
    item: lever.item,
    value: lever.value,
    disabled: lever.is_disabled_in_ui,
    options: lever.options,
    leverGroup: lever.lever_group,
  }));

  const nonPriorityRadios = nonPriorityLevers.map((lever) => ({
    displayText: lever.title,
    item: lever.item,
    value: lever.value,
    disabled: lever.is_disabled_in_ui,
    options: lever.options,
    leverGroup: lever.lever_group,
  }));

  const [priorityToggle, setPriorityToggle] = useState(false);
  const [nonPriorityToggle, setNonPriorityToggle] = useState(false);
  const [comboPriorityToggle, setComboPriorityToggle] = useState(false);
  const [comboNonPriorityToggle, setComboNonPriorityToggle] = useState(false);

  useEffect(() => {
    const allPrioritySelected = priorityRadios.every((lever) => lever.value === 'true');
    const allPriorityUnselected = priorityRadios.every((lever) => lever.value === 'false');
    const allNonPrioritySelected = nonPriorityRadios.every((lever) => lever.value === 'true');
    const allNonPriorityUnselected = nonPriorityRadios.every((lever) => lever.value === 'false');

    if (allPrioritySelected) {
      setPriorityToggle(true);
      setComboPriorityToggle(false);
    } else if (allPriorityUnselected) {
      setPriorityToggle(false);
      setComboPriorityToggle(false);
    } else {
      setPriorityToggle(false);
      setComboPriorityToggle(true);
    }

    if (allNonPrioritySelected) {
      setNonPriorityToggle(true);
      setComboNonPriorityToggle(false);
    } else if (allNonPriorityUnselected) {
      setNonPriorityToggle(false);
      setComboNonPriorityToggle(false);
    } else {
      setNonPriorityToggle(false);
      setComboNonPriorityToggle(true);
    }
  }, [priorityRadios, nonPriorityRadios]);

  const handleToggleChange = (isPriority) => {
    if (isPriority) {
      const toggleState = priorityToggle !== true;

      setPriorityToggle(toggleState);
      const newToggleState = toggleState ? 'true' : 'false';

      priorityRadios.forEach((lever) => {
        dispatch(updateLeverValue(lever.leverGroup, lever.item, newToggleState));
      });
    } else {
      const toggleState = nonPriorityToggle !== true;

      setNonPriorityToggle(toggleState);
      const newToggleState = toggleState ? 'true' : 'false';

      nonPriorityRadios.forEach((lever) => {
        dispatch(updateLeverValue(lever.leverGroup, lever.item, newToggleState));
      });
    }
  };

  const filterOptionValue = (lever) => {
    let enabled = lever?.value;

    if (enabled === 'true') {
      return COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_ON;
    }

    return COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF;
  };

  const buildAriaLabel = (lever, isPriority) => {
    let priority = isPriority ? 'Priority' : 'Non Priority';
    let enabled = lever.value ? 'On' : 'Off';

    return `${priority } ${ lever.title } ${ enabled}`;
  };

  return (
    <div className="exclusion-table-container-styling">
      <table >
        <thead>
          <tr>
            <div className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column" aria-hidden="true"></div>
            <th className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}
            </th>
            <th className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}
            </th>
            <th className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column">
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER}
            </th>
          </tr>
        </thead>
        {isUserAcdAdmin ?
          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-first-col-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
              >
                <span>
                  <h4 className="exclusion-table-header-styling">
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_non_priority}
                    selected = {nonPriorityToggle}
                    toggleSelected = {() => handleToggleChange(false)}
                    isIdle = {comboNonPriorityToggle}
                  />
                </span>
              </td>

              {nonPriorityRadios && nonPriorityRadios.map((lever) => (
                <td
                  className={cx('exclusion-table-styling')}
                  aria-label={buildAriaLabel(lever, false)}
                  key={lever.item}
                >
                  <ExcludeDocketLever lever={lever} />
                </td>
              ))}
            </tr>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-first-col-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
              >
                <span>
                  <h4 className="exclusion-table-header-styling">
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_priority}
                    selected = {priorityToggle}
                    toggleSelected = {() => handleToggleChange(true)}
                    isIdle = {comboPriorityToggle}
                  />
                </span>
              </td>
              {priorityRadios && priorityRadios.map((lever) => (
                <td
                  className={cx('exclusion-table-styling')}
                  aria-label={buildAriaLabel(lever, true)}
                  key={lever.item}
                >
                  <ExcludeDocketLever lever={lever} />
                </td>
              ))}
            </tr>
          </tbody> :

          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <h3 aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3>
              </td>
              {nonPriorityRadios && nonPriorityRadios.map((lever) => (
                <td
                  className={cx('exclusion-table-styling')}
                  aria-label={buildAriaLabel(lever, false)}
                  key={lever.item}
                >
                  <label className="exclusion-table-member-view-styling">
                    {filterOptionValue(lever)}
                  </label>
                </td>
              ))}
            </tr>

            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <h3 aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3>
              </td>
              {priorityRadios && priorityRadios.map((lever) => (
                <td
                  className={cx('exclusion-table-styling')}
                  aria-label={buildAriaLabel(lever, true)}
                  key={lever.item}
                >
                  <label className="exclusion-table-member-view-styling">
                    {filterOptionValue(lever)}
                  </label>
                </td>
              ))}
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
