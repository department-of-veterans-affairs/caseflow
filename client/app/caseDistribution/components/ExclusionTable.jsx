/* eslint-disable camelcase */
import React from 'react';
import { useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import ExcludeDocketLever from './ExcludeDocketLever';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);

  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  const docketLevers = theState.caseDistributionLevers?.levers?.docket_levers ?? [];

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

  const filterOptionValue = (lever) => {
    let enabled = lever?.value;

    if (enabled) {
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
            <th className={cx('table-header-styling', (isUserAcdAdmin) ? '' :
              'table-header-member-styling')} scope="column">{' '}</th>
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
                    selected = {false}
                    disabled
                  />
                </span>
              </td>

              {nonPriorityRadios && nonPriorityRadios.map((lever) => (
                <td className={cx('exclusion-table-styling')} aria-label={buildAriaLabel(lever, false)} >
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
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              {priorityRadios && priorityRadios.map((lever) => (
                <td className={cx('exclusion-table-styling')} aria-label={buildAriaLabel(lever, true)} >
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
                <td className={cx('exclusion-table-styling')} aria-label={buildAriaLabel(lever, false)}>
                  {filterOptionValue(lever)}
                </td>
              ))}
            </tr>

            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <h3 aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3>
              </td>
              {priorityRadios && priorityRadios.map((lever) => (
                <td className={cx('exclusion-table-styling')} aria-label={buildAriaLabel(lever, true)} >
                  {filterOptionValue(lever)}
                </td>
              ))}
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
