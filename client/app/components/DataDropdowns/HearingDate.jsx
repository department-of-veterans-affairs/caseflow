import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  onReceiveDropdownData,
  onFetchDropdownData,
  onDropdownError
} from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import { formatDateStr, getMinutesToMilliseconds } from '../../util/DateUtil';
import LoadingLabel from './LoadingLabel';
import SearchableDropdown from '../SearchableDropdown';

class HearingDateDropdown extends React.Component {
  componentDidMount() {
    this.getHearingDates(false);
  }

  componentDidUpdate(prevProps) {
    const { hearingDates: { options }, validateValueOnMount, onChange } = this.props;

    if (!_.isEqual(prevProps.hearingDates.options, options) && validateValueOnMount) {
      const option = this.getSelectedOption() || {};

      onChange(option.value, option.label);
    }

    if (prevProps.regionalOffice !== this.props.regionalOffice) {
      this.getHearingDates(true);
    }
  }

  getHearingDates = (force) => {
    const { hearingDates: { options, isFetching }, regionalOffice } = this.props;
    const name = `hearingDatesFor${regionalOffice}`;
    const xhrUrl = `/regional_offices/${regionalOffice}/hearing_dates.json`;

    if ((options && !force) || isFetching) {
      return;
    }

    this.props.onFetchDropdownData(name);

    return ApiUtil.
      get(xhrUrl, { timeout: { response: getMinutesToMilliseconds(5) } }).
      then((resp) => {
        const jsonResponse = ApiUtil.convertToCamelCase(resp.body);
        const hearingDateOptions = _.values(jsonResponse.hearingDays).
          map((hearingDate) => {
            const scheduled = formatDateStr(hearingDate.scheduledFor);

            return {
              label: `${scheduled} (${hearingDate.filledSlots}/${hearingDate.totalSlots})`,
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

        this.props.onReceiveDropdownData(name, hearingDateOptions);

        if (hearingDateOptions && hearingDateOptions.length === 1) {
          this.props.onDropdownError(name, 'There are no upcoming hearing dates for this regional office.');
        } else {
          this.props.onDropdownError(name, null);
        }
      });
  }

  getSelectedOption = () => {
    const { value, hearingDates: { options } } = this.props;

    if (!value) {
      return options ? options[0] : {};
    }

    let comparison;

    if (typeof (value) === 'string') {
      comparison = (opt) => opt.value.hearingDate === formatDateStr(value, 'YYYY-MM-DD', 'YYYY-MM-DD');
    } else {
      comparison = (opt) => opt.value === value;
    }

    return _.find(options, comparison);
  }

  onOptionSelected = (option) => {
    const { onChange } = this.props;
    const safeOption = option || {};

    return onChange(safeOption.value, safeOption.label);
  }

  render() {
    const {
      name, label, readOnly, errorMessage, placeholder,
      hearingDates: { options, isFetching, errorMsg }
    } = this.props;

    return (
      <React.Fragment>
        <SearchableDropdown
          name={name}
          label={
            isFetching ? <LoadingLabel text={COPY.HEARING_DATE_LOADING} /> : label
          }
          strongLabel
          readOnly={readOnly}
          value={this.getSelectedOption()}
          onChange={this.onOptionSelected}
          options={options}
          errorMessage={errorMsg || errorMessage}
          placeholder={placeholder} />
      </React.Fragment>
    );
  }
}

HearingDateDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  regionalOffice: PropTypes.string.isRequired,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
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
