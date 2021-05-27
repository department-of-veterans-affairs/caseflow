import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React, { useEffect } from 'react';
import { values, find } from 'lodash';

import { Dot } from '../Dot';
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

export const HearingDateLabel = ({ date, scheduled, vlj }) => {
  return (
    <React.Fragment>
      <strong>{date}</strong>
      <Dot spacing={5} />{' '}
      {scheduled}
      <Dot spacing={5} />{' '}
      {vlj}
    </React.Fragment>
  );
};

HearingDateLabel.propTypes = {
  scheduled: PropTypes.string.isRequired,
  date: PropTypes.string,
  vlj: PropTypes.string,
};

export const HearingDateDropdown = (props) => {
  const {
    name,
    label,
    value,
    hearingDates,
    regionalOffice,
    onChange,
    placeholder,
    errorMessage,
    readOnly
  } = props;

  const hearingDateOptions = hearingDates?.options;

  const fetchRegionalOfficeHearingDates = (ro) => {
    const xhrUrl = `/regional_offices/${ro}/hearing_dates.json`;

    return ApiUtil.
      get(xhrUrl, { timeout: { response: getMinutesToMilliseconds(5) } });
  };

  // fetch hearing dates for RO and format
  const getHearingDates = () => {
    // ex `hearingDatesForRO17`
    const dropdownKeyForRo = `hearingDatesFor${regionalOffice}`;

    // no need to fetch
    if (hearingDateOptions || hearingDates?.isFetching) {
      return;
    }

    props.onFetchDropdownData(dropdownKeyForRo);

    return fetchRegionalOfficeHearingDates(regionalOffice).
      then((resp) => {
        // format data
        const jsonResponse = ApiUtil.convertToCamelCase(resp.body);
        const dateOptionsForRO = values(jsonResponse.hearingDays).
          map((hearingDate) => ({
            label: (
              <HearingDateLabel
                date={formatDateStr(hearingDate.scheduledFor, 'YYYY-MM-DD', 'ddd MMM D')}
                scheduled={`${hearingDate.filledSlots} of ${ hearingDate.totalSlots } scheduled`}
                vlj={hearingDate.vlj}
              />
            ),
            value: {
              ...hearingDate,
              hearingDate: formatDateStr(
                hearingDate.scheduledFor,
                'YYYY-MM-DD',
                'YYYY-MM-DD'
              ),
            },
          })
          );

        // sort dates in ascending order
        dateOptionsForRO?.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));

        // add empty value as the first item on list
        dateOptionsForRO?.unshift(
          {
            label: ' ',
            value: {
              hearingId: null,
              hearingDate: null
            }
          }
        );

        props.onReceiveDropdownData(dropdownKeyForRo, dateOptionsForRO);

        if (dateOptionsForRO && dateOptionsForRO.length === 1) {
          props.onDropdownError(dropdownKeyForRo, 'There are no upcoming hearing dates for this regional office.');
        } else {
          props.onDropdownError(dropdownKeyForRo, null);
        }
      });
  };

  // return the last selected hearing date for RO
  const getSelectedOption = () => {
    // no history of date selection, return first item on list
    if (!value) {
      return hearingDateOptions ? hearingDateOptions[0] : {};
    }

    let comparison;

    // determine if any selection was made
    if (typeof (value) === 'string') {
      comparison = (opt) => opt?.value.hearingDate === formatDateStr(value, 'YYYY-MM-DD', 'YYYY-MM-DD');
    } else {
      comparison = (opt) => opt?.value === value;
    }

    // find which date was selected from list of hearing dates
    return find(hearingDateOptions, comparison);
  };

  // on mount and if new RO is selected
  useEffect(() => {
    setTimeout(() => getHearingDates(), 0);
  }, [regionalOffice]);

  // only if there's new set of hearingDateOptions, triggered by a RO change
  useEffect(() => {
    const option = getSelectedOption() || {};

    onChange(option.value, option.label);
  }, [hearingDateOptions]);

  return (
    <React.Fragment>
      <SearchableDropdown
        name={name}
        label={
          hearingDates?.isFetching ? <LoadingLabel text={COPY.HEARING_DATE_LOADING} /> : label
        }
        strongLabel
        readOnly={readOnly}
        value={getSelectedOption()}
        onChange={(option) => onChange(option?.value, option?.label)}
        options={hearingDateOptions}
        errorMessage={hearingDates?.errorMsg || errorMessage}
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
  errorMessage: PropTypes.string
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
