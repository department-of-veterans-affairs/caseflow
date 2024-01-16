import React from 'react';
import { useSelector } from 'react-redux';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import RadioField from 'app/components/RadioField';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';
import { getUserIsAcdAdmin } from '../reducers/levers/leversSelector';

const ExclusionTable = () => {
  const theState = useSelector((state) => state);

  const isUserAcdAdmin = getUserIsAcdAdmin(theState);

  // Placeholder options until future implementation
  let options = [
    { displayText: 'On',
      value: '1',
      disabled: true
    },
    { displayText: 'Off',
      value: '2',
      disabled: true
    }
  ];

  return (
    <div className='exclusion-table-container-styling'>
      <table >
        <thead>
          <tr>
            <th className='table-header-styling'>{' '}</th>
            <th className='table-header-styling'>
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}</th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}</th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER}</th>
          </tr>
        </thead>
        {isUserAcdAdmin ?
          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <h4 className='exclusion-table-header-styling'>
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_non_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
            </tr>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <h4 className='exclusion-table-header-styling'>
                    {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}
                  </h4>
                  <ToggleSwitch
                    id = {DISTRIBUTION.all_priority}
                    selected = {false}
                    disabled
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              </td>
            </tr>
          </tbody> :

          <tbody>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label>
              </td>
            </tr>
            <tr>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <h3>All Priority</h3>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>Off</label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>Off</label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>Off</label>
              </td>
              <td className={cx('exclusion-table-styling', 'lever-disabled')}>
                <label className={'exclusion-table-member-view-styling'}>Off</label>
              </td>
            </tr>
          </tbody> }
      </table>
    </div>
  );
};

export default ExclusionTable;
