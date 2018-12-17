import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from './SearchableDropdown';
import InlineForm from './InlineForm';
import Button from './Button';
import ApiUtil from '../util/ApiUtil';
import { onReceiveHearingDays } from './common/actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import { formatDateStr } from '../util/DateUtil';
import { loadingSymbolHtml } from './RenderFunctions';

class HearingDayDropdown extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      editable: false,
      loading: false
    };
  }

  loadHearingDays = () => {

    const { regionalOffice } = this.props;

    this.setState({ loading: true });
    
    return ApiUtil.get(`/regional_offices/${regionalOffice}/open_hearing_dates.json`).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveHearingDays(resp.hearingDays);
      this.setState({ loading: false });
    });

  };

  componentWillMount() {
    if (!this.props.hearingDays) {
      this.loadHearingDays();
    }
  }

  componentDidUpdate() {
    const { value, onChange } = this.props;

    if (this.hearingDayOptions().length && typeof (value) === 'string') {
      onChange(this.getValue());
    }
  }

  getValue = () => {
    const { value } = this.props;

    if (typeof (value) === 'string') {
      return _.find(this.hearingDayOptions(), (day) => day.value.hearingDate === value) || {};
    }

    return value || {};
  }

  hearingDayOptions = () => {

    let hearingDayOptions = [];

    _.forEach(this.props.hearingDays, (day) => {
      hearingDayOptions.push({
        label: formatDateStr(day.hearingDate),
        value: { ...day,
          hearingDate: formatDateStr(day.hearingDate, 'YYYY-MM-DD', 'YYYY-MM-DD') }
      });
    });

    if (this.props.staticOptions) {
      hearingDayOptions.push(...this.props.staticOptions);
    }

    return hearingDayOptions.sort((d1, d2) => new Date(d1.value.hearingDate) - new Date(d2.value.hearingDate));
  };

  render() {
    const { readOnly, onChange, placeholder } = this.props;
    const hearingDayOptions = this.hearingDayOptions();

    if ((!this.props.changePrompt || this.state.editable) && !this.state.loading) {
      return (
        <SearchableDropdown
          name="hearing_date"
          label="Date of Hearing"
          options={hearingDayOptions || []}
          readOnly={readOnly || false}
          onChange={onChange}
          value={this.getValue()}
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
            {this.getValue().label}
          </p>
          {!this.state.loading && <Button
            name="Change"
            linkStyling
            onClick={() => {
              this.setState({ editable: true });
            }} />}
          {this.state.loading && loadingSymbolHtml('', '20px')}
        </InlineForm>

      </React.Fragment>
    );
  }
}

HearingDayDropdown.propTypes = {
  regionalOffice: PropTypes.string.isRequired,
  hearingDays: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  placeholder: PropTypes.string,
  staticOptions: PropTypes.array,
  readOnly: PropTypes.bool,
  changePrompt: PropTypes.bool
};

const mapStateToProps = (state) => ({
  hearingDays: state.components.hearingDays
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveHearingDays
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(HearingDayDropdown);
