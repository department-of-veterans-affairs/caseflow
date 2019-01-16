import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from './actions';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';
import { formatDateStr } from '../../../util/DateUtil';

import SearchableDropdown from '../../../components/SearchableDropdown';

class HearingDateDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getHearingDates, 0);
  }

  getHearingDates = () => {
    const { hearingDates: { options, isFetching }, regionalOffice } = this.props;
    const name = `hearingDatesFor${regionalOffice}`;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData(name);

    return ApiUtil.get(`/regional_offices/${regionalOffice}/open_hearing_dates.json`).then((resp) => {
      const hearingDateOptions = _.values(ApiUtil.convertToCamelCase(resp.body)).map((hearingDate) => ({
        label: formatDateStr(hearingDate.scheduledFor),
        value: { ...hearingDate,
          hearingDate: formatDateStr(hearingDate.scheduledFor, 'YYYY-MM-DD', 'YYYY-MM-DD') }
      }));

      hearingDateOptions.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));
      this.props.onReceiveDropdownData(name, hearingDateOptions);
    });
  }

  componentDidUpdate() {
    const { hearingDates: { options }, value, onChange } = this.props;

    if (options && typeof (value) === 'string') {
      onChange(this.getValue());
    }
  }

  getValue = () => {
    const { value, hearingDates: { options } } = this.props;

    if (!value) {
      return null;
    }

    if (typeof (value) === 'string') {
      return _.find(options, (opt) => opt.value === value);
    }

    return value;
  }

  render() {
    const { name, label, onChange } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        value={this.getValue()}
        onChange={onChange}
        options={this.props.hearingDates.options} />
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
  onChange: PropTypes.func.isRequired
};

HearingDateDropdown.defaultProps = {
  name: 'hearingDate',
  label: 'Hearing Date'
};

const mapStateToProps = (state, props) => ({
  hearingDates: state.hearingDropdownData[`hearingDatesFor${props.regionalOffice}`] ? {
    options: state.hearingDropdownData[`hearingDatesFor${props.regionalOffice}`].options,
    isFetching: state.hearingDropdownData[`hearingDatesFor${props.regionalOffice}`].isFetching
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
