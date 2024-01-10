import React from 'react';
import ToggleSwitch from 'app/components/ToggleSwitch/ToggleSwitch';
import PropTypes from 'prop-types';
import RadioField from 'app/components/RadioField';
import cx from 'classnames';
import COPY from '../../../COPY';
import DISTRIBUTION from '../../../constants/DISTRIBUTION';

const ExclusionTable = (props) => {
  let isMemberUser = !props.isAdmin;
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
        <tbody>
          <tr>
            <th className='table-header-styling'>{' '}</th>
            <th className='table-header-styling'>
              {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_LEGACY_APPEALS_HEADER}
            </th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_HEARINGS_HEADER}</th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_DIRECT_HEADER}</th>
            <th className='table-header-styling'>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_AMA_EVIDENCE_HEADER}</th>
          </tr>
          <tr>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_NON_PRIORITY}</h3> :
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
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
          </tr>
          <tr>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <h3>{COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_PRIORITY}</h3> :
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
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
            <td className={cx('exclusion-table-styling', 'lever-disabled')}>
              {isMemberUser ?
                <label className='exclusion-table-member-view-styling'>
                  {COPY.CASE_DISTRIBUTION_EXCLUSION_TABLE_OFF}
                </label> :
                <span>
                  <RadioField
                    name=""
                    options={options}
                    vertical
                  />
                </span>
              }
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

ExclusionTable.propTypes = {
  isAdmin: PropTypes.bool.isRequired,
};
export default ExclusionTable;
