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

  render() {
    const { readOnly, onChange, value, placeholder } = this.props;
    const regionalOfficeOptions = this.regionalOfficeOptions();

    if (!this.props.changePrompt || this.state.editable) {
      return (
        <SearchableDropdown
          name="ro"
          label="Regional Office"
          options={regionalOfficeOptions || []}
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
          display: 'block' }}>Regional Office</b>
        <InlineForm>
          <p style={{ marginRight: '30px',
            width: '150px' }}>
            {value.label}
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
  value: PropTypes.object,
  placeholder: PropTypes.string,
  staticOptions: PropTypes.array,
  readOnly: PropTypes.bool,
  changePrompt: PropTypes.bool
};

const mapStateToProps = (state) => ({
  regionalOffices: state.components.regionalOffices
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveRegionalOffices
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(RoSelectorDropdown);
