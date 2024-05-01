import React from 'react';
import { useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import ExcludeDocketLever from './ExcludeDocketLever';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  const getOptionData = () => {
    let options = theState.caseDistributionLevers.levers.docket_levers?.map((opt) => ({
      item: opt.item,
      value: opt.value,
      disabled: opt.is_disabled_in_ui
    })
    );

    return options;
  };

  let optionData = getOptionData();

  const filterOption = (item) => {
    return optionData?.find((opt) => opt.item === item);
  };

  const filterOptionValue = (item) => {
    let enabled = optionData?.find((opt) => opt.item === item)?.value;

    if (enabled) {
      return COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_ON;
    }

    return COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF;
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
              <td className={cx('exclusion-table-styling', 'exclusion-first-col-styling')}
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
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY_LEGACY}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_legacy_non_priority)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY_AMA_HEARING}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_non_priority_hearing)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY_AMA_DIRECT_REVIEW}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_non_priority_direct_review)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY_AMA_EVIDENCE}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_non_priority_evidence_sub)}
                />
              </td>
            </tr>
            <tr>
              <td className={cx('exclusion-table-styling', 'exclusion-first-col-styling')}
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
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY_LEGACY}>
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_legacy_priority)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY_AMA_HEARING}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_priority_hearing)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY_AMA_DIRECT_REVIEW}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_priority_direct_review)}
                />
              </td>
              <td className={cx('exclusion-table-styling')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY_AMA_EVIDENCE}
              >
                <ExcludeDocketLever
                  lever={filterOption(DISTRIBUTION.disable_ama_priority_evidence_sub)}
                />
              </td>
            </tr>
          </tbody> :

          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <h3 aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_legacy_non_priority) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_non_priority_hearing) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_non_priority_direct_review) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_non_priority_evidence_sub) }
                </label>
              </td>
            </tr>

            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <h3 aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_legacy_priority) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_priority_hearing) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_priority_direct_review) }
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  { filterOptionValue(DISTRIBUTION.disable_ama_priority_evidence_sub) }
                </label>
              </td>
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
