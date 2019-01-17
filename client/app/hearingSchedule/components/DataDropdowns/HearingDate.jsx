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

  getSelectedOption = () => {
    const { value, hearingDates: { options } } = this.props;

    return _.find(options, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const { name, label, onChange, readOnly } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value)}
        options={this.props.hearingDates.options} />
    );
  }
}

HearingDateDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  regionalOffice: PropTypes.string.isRequired,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool
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
