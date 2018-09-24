import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from '../../components/SearchableDropdown';
import ApiUtil from "../../util/ApiUtil";
import {onReceiveRegionalOffices} from '../actions';
import {bindActionCreators} from "redux";
import connect from "react-redux/es/connect/connect";

const regionalOfficeDropdowns = [];

class RoSelectorDropdown extends React.Component {

  loadRegionalOffices = () => {
    return ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveRegionalOffices(resp.regionalOffices);
      this.regionalOfficeOptions();
    });
  };

  componentWillMount(){
    console.log("*** RO component did mount ***")
    if (!this.props.regionalOffices) {
      this.loadRegionalOffices();
    }
  };



  regionalOfficeOptions = () => {

    _.forEach(this.props.regionalOffices, (value, key) => {
      regionalOfficeDropdowns.push({
        label: `${value.city}, ${value.state}`,
        value: key
      });
    });

    regionalOfficeDropdowns.push({
      label: 'Central Office',
      value: 'C'
    });

    return _.orderBy(regionalOfficeDropdowns, (ro) => ro.label, 'asc');
  };

  render() {
    return <SearchableDropdown
      name="ro"
      label="Regional Office"
      options={regionalOfficeDropdowns}
      onChange={this.props.onChange}
      value={this.props.value}
      placeholder={this.props.placeholder}
    />;
  }
}

RoSelectorDropdown.propTypes = {
  regionalOffices: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.object,
  placeholder: PropTypes.string
};

const mapStateToProps = (state) => ({
  regionalOffices: state.regionalOffices
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveRegionalOffices
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(RoSelectorDropdown);