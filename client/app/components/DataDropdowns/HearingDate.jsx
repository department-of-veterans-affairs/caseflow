import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React, { useEffect } from 'react';
import { isEqual, values, find } from 'lodash';

import { formatDateStr, getMinutesToMilliseconds } from '../../util/DateUtil';
import {
  onReceiveDropdownData,
  onFetchDropdownData,
  onDropdownError
} from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import LoadingLabel from './LoadingLabel';
import SearchableDropdown from '../SearchableDropdown';

const HearingDateDropdown = (
  {
    name, label, value, hearingDates, regionalOffice, onChange, readOnly,
    placeholder, errorMessage, validateValueOnMount, onFetchDropdownData,
    onReceiveDropdownData, onDropdownError
  }
) => {
  const hearingDateOptions = hearingDates.options;

  const getSelectedOption = () => {
    if (!value) {
      return hearingDateOptions ? hearingDateOptions[0] : {};
    }

    let comparison;

    if (typeof (value) === 'string') {
      comparison = (opt) => opt?.value.hearingDate === formatDateStr(value, 'YYYY-MM-DD', 'YYYY-MM-DD');
    } else {
      comparison = (opt) => opt?.value === value;
    }

    find(hearingDateOptions, comparison);
  }

  const getHearingDates = (force) => {
    const name = `hearingDatesFor${regionalOffice}`;
    const xhrUrl = `/regional_offices/${regionalOffice}/hearing_dates.json`;

    // currently fetching the dates
    if ((hearingDateOptions && !force) || hearingDates.isFetching) {
      return;
    }

    onFetchDropdownData(name);

    return ApiUtil.
      get(xhrUrl, { timeout: { response: getMinutesToMilliseconds(5) } }).
      then((resp) => {
        const jsonResponse = ApiUtil.convertToCamelCase(resp.body);
        const hearingDateOptions = _.values(jsonResponse.hearingDays).
          map((hearingDate) => {
            const scheduled = formatDateStr(hearingDate.scheduledFor);

            return {
              label: `${scheduled} ${hearingDate.room} (${hearingDate.filledSlots}/${hearingDate.totalSlots})`,
              value: {
                ...hearingDate,
                hearingDate: formatDateStr(hearingDate.scheduledFor, 'YYYY-MM-DD', 'YYYY-MM-DD')
              }
            };
          });

        hearingDateOptions.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));

        hearingDateOptions.unshift(
          {
            label: ' ',
            value: {
              hearingId: null,
              hearingDate: null
            }
          }
        );

        onReceiveDropdownData(name, hearingDateOptions);

        if (hearingDateOptions && hearingDateOptions.length === 1) {
          onDropdownError(name, 'There are no upcoming hearing dates for this regional office.');
        } else {
          onDropdownError(name, null);
        }
      });
  }

  // only if different RO is selected
  useEffect(() => {
    const timer = setTimeout(() => getHearingDates(true), 0);
    return () => {
      clearTimeout(timer)
    }
  }, [regionalOffice])

  // only if there's new set of hearingDateOptions
  useEffect(() => {
    if (validateValueOnMount) {
      const option = getSelectedOption() || {};

      onChange(option.value, option.label);
    }
  }, [hearingDateOptions])

  const onOptionSelected = (option) => {
    onChange(option?.value, option?.label);
  }

  return (
    <React.Fragment>
      <SearchableDropdown
        name={name}
        label={
          hearingDates.isFetching ? <LoadingLabel text={COPY.HEARING_DATE_LOADING} /> : label
        }
        strongLabel
        readOnly={readOnly}
        value={getSelectedOption}
        onChange={onOptionSelected}
        options={hearingDateOptions}
        errorMessage={hearingDates.errorMsg || errorMessage}
        placeholder={placeholder}
      />
    </React.Fragment>
  );
};

HearingDateDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  hearingDates: PropTypes.shape({
    options: PropTypes.arrayOf(
      PropTypes.shape({
        value: PropTypes.any,
        label: PropTypes.string,
      })
    ),
    isFetching: PropTypes.bool,
    errorMsg: PropTypes.string
  }),
  regionalOffice: PropTypes.string.isRequired,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
  onDropdownError: PropTypes.func,
  onFetchDropdownData: PropTypes.func,
  onReceiveDropdownData: PropTypes.func,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string,
  validateValueOnMount: PropTypes.bool
};

HearingDateDropdown.defaultProps = {
  name: 'hearingDate',
  label: 'Hearing Date'
};

const mapStateToProps = (state, props) => ({
  hearingDates: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`] ? {
    options: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`].options,
    isFetching: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`].isFetching,
    errorMsg: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`].errorMsg
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData,
  onDropdownError
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingDateDropdown);
