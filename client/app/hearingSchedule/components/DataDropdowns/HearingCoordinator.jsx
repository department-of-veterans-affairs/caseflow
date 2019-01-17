import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from './actions';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../../../components/SearchableDropdown';

class HearingCoordinatorDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getCoordinators, 0);
  }

  getCoordinators = () => {
    const { hearingCoordinators: { options, isFetching } } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData('hearingCoordinators');

    ApiUtil.get('/users?role=HearingCoordinator').then((resp) => {
      const coordinatorOptions = _.values(ApiUtil.convertToCamelCase(resp.body.coordinators)).map((coor) => ({
        label: coor.fullName,
        value: coor.cssId
      }));

      coordinatorOptions.sort((first, second) => (first.label - second.label));

      this.props.onReceiveDropdownData('hearingCoordinators', coordinatorOptions);
    });
  }

  getSelectedOption = () => {
    const { value, hearingCoordinators: { options } } = this.props;

    return _.find(options, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const { name, label, onChange } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value)}
        options={this.props.hearingCoordinators.options} />
    );
  }
}

HearingCoordinatorDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired
};

HearingCoordinatorDropdown.defaultProps = {
  name: 'coordinator',
  label: 'Hearing Coordinator'
};

const mapStateToProps = (state) => ({
  hearingCoordinators: {
    options: state.hearingDropdownData.hearingCoordinators.options,
    isFetching: state.hearingDropdownData.hearingCoordinators.isFetching
  }
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingCoordinatorDropdown);
