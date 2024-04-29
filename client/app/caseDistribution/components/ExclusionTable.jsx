import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';
import { updateLeverValue } from '../reducers/levers/leversActions';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);
  const dispatch = useDispatch();
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);
  const LEVER_GROUP = ACD_LEVERS.lever_groups.docket_levers;

  const getOptionData = () => {
    let options = theState.caseDistributionLevers.levers.docket_levers.map((opt) => ({
      item: opt.item,
      value: opt.value,
      disabled: opt.is_disabled_in_ui
    })
    );

    return options;
  };

  let optionData = getOptionData();

  const filterOption = (item) => {

    return optionData.find((opt) => opt.item === item);
  };

  const onChangeSelected = (lever) => (event) => {
    // eslint-disable-next-line camelcase
    const { item } = lever;

    dispatch(updateLeverValue(LEVER_GROUP, item, event));
  };

  const options = [
    { displayText: 'On',
      value: 'true',
      disabled: false
    },
    { displayText: 'Off',
      value: 'false',
      disabled: false
    }
  ];

  const generateUniqueId = (leverItem, optionValue, index) => `${leverItem}-${optionValue}-${index}`;

  onChangeSelected(filterOption(DISTRIBUTION.disable_ama_non_priority_hearing));
  // console.log(optionData);

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
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_legacy_non_priority).value}
                    options={options}
                    onChange={onChangeSelected(filterOption(DISTRIBUTION.disable_legacy_non_priority))}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_non_priority_hearing).value}
                    options={options}
                    onChange={onChangeSelected(filterOption(DISTRIBUTION.disable_ama_non_priority_hearing))}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_non_priority_direct_review).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_non_priority_evidence_sub).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_non_priority, option.value, index)}
                  />
                </span>
              </td>
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
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}>
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_legacy_priority).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_priority_hearing).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_priority_direct_review).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}
                aria-label={COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
              >
                <span>
                  <RadioField
                    name=""
                    value={filterOption(DISTRIBUTION.disable_ama_priority_evidence_sub).value}
                    options={options}
                    vertical
                    uniqueIdGenerator={(option, index) =>
                      generateUniqueId(DISTRIBUTION.all_priority, option.value, index)}
                  />
                </span>
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
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
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
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}</label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled', 'exclusion-table-member-styling')}>
                <label className="exclusion-table-member-view-styling">
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
