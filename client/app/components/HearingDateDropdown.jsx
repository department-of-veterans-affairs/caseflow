import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from './SearchableDropdown';
import InlineForm from './InlineForm';
import Button from './Button';
import ApiUtil from '../util/ApiUtil';
import { onReceiveHearingDates } from './common/actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import { formatDateStr, formatDateStringForApi } from '../util/DateUtil';

class HearingDateDropdown extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      editable: false
    };
  }

  loadHearingDates = () => {

    const { regionalOffice } = this.props;

    return ApiUtil.get(`/regional_offices/${regionalOffice}/open_hearing_dates.json`).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveHearingDates(resp.hearingDates);
    });

  };

  componentWillMount() {
    if (!this.props.hearingDates) {
      this.loadHearingDates();
    }
  }

  hearingDateOptions = () => {

    let hearingDateOptions = [];

    _.forEach(this.props.hearingDates, (date) => {
      hearingDateOptions.push({
        label: formatDateStr(date.hearingDate),
        value: formatDateStr(date.hearingDate, undefined, 'YYYY-MM-DD')
      });
    });

    if (this.props.staticOptions) {
      hearingDateOptions.push(...this.props.staticOptions);
    }

    return hearingDateOptions.sort((a,b) => (
      a.value > b.value ? 1 : (a.value < b.value ? -1 : 0)
    ));
  };

  render() {
    const { readOnly, onChange, value, placeholder } = this.props;
    const hearingDateOptions = this.hearingDateOptions();
    const selectedHearingDate = _.find(hearingDateOptions, (opt) => opt.value === value) || {};

    if (!this.props.changePrompt || this.state.editable) {
      return (
        <SearchableDropdown
          name="hearing_date"
          label="Date of Hearing"
          options={hearingDateOptions}
          readOnly={readOnly || false}
          onChange={onChange}
          value={value}
          placeholder={placeholder}
        />
      );
    }

    return (
      <React.Fragment>
        <b style={{ marginBottom: '-8px',
          marginTop: '8px',
          display: 'block' }}>Date of Hearing</b>
        <InlineForm>
          <p style={{ marginRight: '30px',
            width: '150px' }}>
            {selectedHearingDate.label}
          </p>
          <Button
            name="Change"
            linkStyling
            onClick={() => {
              this.setState({ editable: true });
            }} />
        </InlineForm>
      </React.Fragment>
    );
  }
}

HearingDateDropdown.propTypes = {
  regionalOffice: PropTypes.string.isRequired,
  hearingDates: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.object,
  placeholder: PropTypes.string,
  staticOptions: PropTypes.array,
  readOnly: PropTypes.bool,
  changePrompt: PropTypes.bool
};

const mapStateToProps = (state) => ({
  hearingDates: state.components.hearingDates
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveHearingDates
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(HearingDateDropdown);
