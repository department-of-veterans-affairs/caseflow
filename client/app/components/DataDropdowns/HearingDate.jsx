import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import { formatDateStr } from '../../util/DateUtil';

import SearchableDropdown from '../SearchableDropdown';

class HearingDateDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getHearingDates, 0);
  }

  componentDidUpdate(prevProps) {
    const { hearingDates: { options }, validateValueOnMount, onChange } = this.props;

    if (!_.isEqual(prevProps.hearingDates.options, options) && validateValueOnMount) {
      const option = this.getSelectedOption() || {};

      onChange(option.value, option.label);
    }

    if (prevProps.regionalOffice !== this.props.regionalOffice) {
      setTimeout(() => this.getHearingDates(true), 0);
    }
  }

  getHearingDates = (force) => {
    const { hearingDates: { options, isFetching }, regionalOffice } = this.props;
    const name = `hearingDatesFor${regionalOffice}`;

    if ((options && !force) || isFetching) {
      return;
    }

    this.props.onFetchDropdownData(name);

    return ApiUtil.get(`/regional_offices/${regionalOffice}/open_hearing_dates.json`).then((resp) => {
      const hearingDateOptions = _.values(ApiUtil.convertToCamelCase(resp.body).hearingDays).map((hearingDate) => ({
        label: formatDateStr(hearingDate.scheduledFor),
        value: { ...hearingDate,
          hearingDate: formatDateStr(hearingDate.scheduledFor, 'YYYY-MM-DD', 'YYYY-MM-DD') }
      }));

      const ids = _.map(hearingDateOptions, (opt) => opt.value.hearingId);

      if (this.props.staticOptions) {

        _.forEach(this.props.staticOptions, (opt) => {
          if (_.includes(ids, opt.value.hearingId)) {
            return;
          }

          hearingDateOptions.push({
            label: opt.label,
            value: {
              ...opt.value,
              hearingDate: formatDateStr(opt.value.scheduledFor, 'YYYY-MM-DD', 'YYYY-MM-DD')
            }
          });
        });
      }

      hearingDateOptions.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));

      hearingDateOptions.unshift({
        label: ' ',
        value: {
          hearingId: null,
          hearingDate: null
        }
      });

      this.props.onReceiveDropdownData(name, hearingDateOptions);
    });
  }

  getSelectedOption = () => {
    const { value, hearingDates: { options } } = this.props;

    if (!value) {
      return options ? options[0] : {};
    }

    const comparison = typeof (value) === 'string' ?
      (opt) => opt.value.hearingDate === formatDateStr(value, 'YYYY-MM-DD', 'YYYY-MM-DD') :
      (opt) => opt.value === value;

    return _.find(options, comparison);
  }

  render() {
    const { name, label, onChange, readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={this.props.hearingDates.options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
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
  validateValueOnMount: PropTypes.bool,
  staticOptions: PropTypes.array
};

HearingDateDropdown.defaultProps = {
  name: 'hearingDate',
  label: 'Hearing Date'
};

const mapStateToProps = (state, props) => ({
  hearingDates: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`] ? {
    options: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`].options,
    isFetching: state.components.dropdowns[`hearingDatesFor${props.regionalOffice}`].isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingDateDropdown);
