import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from './SearchableDropdown';
import InlineForm from './InlineForm';
import Button from './Button';
import ApiUtil from '../util/ApiUtil';
import { onReceiveRegionalOffices } from './common/actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';

class RoSelectorDropdown extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      editable: false
    };
  }

  loadRegionalOffices = () => {
    return ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveRegionalOffices(resp.regionalOffices);
      this.regionalOfficeOptions();
    });
  };

  componentWillMount() {
    if (!this.props.regionalOffices) {
      this.loadRegionalOffices();
    }
  }

  componentDidUpdate() {
    const { value, onChange } = this.props;

    if (this.regionalOfficeOptions().length && typeof (value) === 'string') {
      onChange(this.getValue());
    }
  }

  getValue = () => {
    const { value } = this.props;

    if (typeof (value) === 'string') {
      return _.find(this.regionalOfficeOptions(), (ro) => ro.value === value) || {};
    }

    return value || {};
  }

  regionalOfficeOptions = () => {

    let regionalOfficeDropdowns = [];

    _.forEach(this.props.regionalOffices, (value, key) => {
      regionalOfficeDropdowns.push({
        label: `${value.city}, ${value.state}`,
        value: key
      });
    });

    if (this.props.staticOptions) {
      regionalOfficeDropdowns.push(...this.props.staticOptions);
    }

    return _.orderBy(regionalOfficeDropdowns, (ro) => ro.label, 'asc');
  };

  labelMessage = this.props.label || 'Regional Office';

  render() {
    const { readOnly, onChange, placeholder, strongLabel, hideLabel, errorMessage } = this.props;
    const regionalOfficeOptions = this.regionalOfficeOptions();

    if (!this.props.changePrompt || this.state.editable) {
      return (
        <SearchableDropdown
          name="ro"
          label={this.labelMessage}
          strongLabel={strongLabel}
          hideLabel={hideLabel}
          options={regionalOfficeOptions || []}
          readOnly={readOnly || false}
          onChange={onChange}
          value={this.getValue()}
          placeholder={placeholder}
          errorMessage={errorMessage}
        />
      );
    }

    return (
      <React.Fragment>
        <b style={{ marginBottom: '-8px',
          marginTop: '8px',
          display: 'block' }}>Regional Office</b>
        <InlineForm>
          <p style={{ marginRight: '30px',
            width: '150px' }}>
            {this.getValue().label}
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

RoSelectorDropdown.propTypes = {
  regionalOffices: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  placeholder: PropTypes.string,
  staticOptions: PropTypes.array,
  hideLabel: PropTypes.bool,
  label: PropTypes.string,
  strongLabel: PropTypes.bool,
  readOnly: PropTypes.bool,
  changePrompt: PropTypes.bool,
  errorMessage: PropTypes.string,
  initialValStr: PropTypes.string
};

const mapStateToProps = (state) => ({
  regionalOffices: state.components.regionalOffices
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveRegionalOffices
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(RoSelectorDropdown);
