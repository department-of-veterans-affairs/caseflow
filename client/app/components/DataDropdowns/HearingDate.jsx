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

export const HearingDateLabel = ({ date, requestType, scheduled, detail }) => {
  return (
    <React.Fragment>
      <strong>{date}</strong>
      <Dot spacing={5} />{' '}
      {requestType}
      <Dot spacing={5} />{' '}
      {scheduled}
      {detail && (
        <React.Fragment>
          <Dot spacing={5} />{' '}
          {detail}
        </React.Fragment>
      )}
    </React.Fragment>
  );
};

HearingDateLabel.propTypes = {
  scheduled: PropTypes.string.isRequired,
  requestType: PropTypes.string,
  date: PropTypes.string,
  detail: PropTypes.string,
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

  // Map over the hearing dates to attach the formatted label to each option
  const formatHearingDays = (hearingDays) => hearingDays.map((hearingDate) => ({
    label: (
      <HearingDateLabel
        requestType={hearingDate.readableRequestType}
        date={formatDateStr(hearingDate.scheduledFor, 'YYYY-MM-DD', 'ddd MMM D')}
        scheduled={`${hearingDate.filledSlots} of ${ hearingDate.totalSlots } scheduled`}
        detail={hearingDate.vlj || hearingDate.roomLabel}
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
  }));

  // fetch hearing dates for RO and format
  const getHearingDates = () => {
    // ex `hearingDatesForRO17`
    const dropdownKeyForRo = `hearingDatesFor${regionalOffice}`;

    if (!hearingDates?.isFetching && hearingDateOptions && !hearingDateOptions?.length && regionalOffice) {
      props.onDropdownError(dropdownKeyForRo, 'There are no upcoming hearing dates for this regional office.');
    }

    // no need to fetch
    if (hearingDateOptions || hearingDates?.isFetching) {
      return;
    }

    props.onFetchDropdownData(dropdownKeyForRo);

    return fetchRegionalOfficeHearingDates(regionalOffice).
      then((resp) => {
        // format data
        const jsonResponse = ApiUtil.convertToCamelCase(resp.body);
        const dateOptionsForRO = formatHearingDays(values(jsonResponse.hearingDays));

        // sort dates in ascending order
        dateOptionsForRO?.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));

        props.onReceiveDropdownData(dropdownKeyForRo, dateOptionsForRO);

        if (dateOptionsForRO) {
          props.onDropdownError(dropdownKeyForRo, null);
        } else {
          props.onDropdownError(dropdownKeyForRo, 'There are no upcoming hearing dates for this regional office.');
        }
      });
  };

  // return the last selected hearing date for RO
  const getSelectedOption = () => {
    const dateOptions = hearingDateOptions?.map((opt) => opt.value.hearingDate);

    // no history of date selection, return first item on list
    if (!value || !dateOptions?.includes(value?.hearingDate)) {
      return hearingDateOptions ? hearingDateOptions[0] : {};
    }

    const hearingIds = hearingDateOptions?.map((opt) => opt.value.hearingId);
    const comparison = (opt) =>
      value?.hearingId && hearingIds.includes(value?.hearingId) ?
        opt?.value?.hearingId === value?.hearingId :
        opt?.value.hearingDate === value.hearingDate;

    // find which date was selected from list of hearing dates
    return find(hearingDateOptions, comparison);
  };

  // on mount and if new RO is selected
  useEffect(() => {
    if (!hearingDateOptions?.length) {
      getHearingDates();
    }

    const option = getSelectedOption() || {};

    onChange(option.value, option.label);
  }, [regionalOffice, hearingDateOptions]);

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
