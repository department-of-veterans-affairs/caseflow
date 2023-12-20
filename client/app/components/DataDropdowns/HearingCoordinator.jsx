import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import LoadingLabel from './LoadingLabel';

import SearchableDropdown from '../SearchableDropdown';
import COPY from '../../../COPY';

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
        value: coor.fullName
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
    const {
      optional, name, label, onChange, readOnly, errorMessage, placeholder,
      hearingCoordinators: { isFetching }
    } = this.props;

    return (
      <SearchableDropdown
        optional={optional}
        name={name}
        label={isFetching ? <LoadingLabel text="Loading hearing coordinators..." /> : label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={this.props.hearingCoordinators.options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

HearingCoordinatorDropdown.propTypes = {
  optional: PropTypes.bool,
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  onFetchDropdownData: PropTypes.func,
  onReceiveDropdownData: PropTypes.func.isRequired,
  hearingCoordinators: PropTypes.shape({
    options: PropTypes.arrayOf(PropTypes.object),
    isFetching: PropTypes.bool
  }),
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

HearingCoordinatorDropdown.defaultProps = {
  name: 'coordinator',
  label: COPY.DROPDOWN_LABEL_HEARING_COORDINATOR
};

const mapStateToProps = (state) => ({
  hearingCoordinators: state.components.dropdowns.hearingCoordinators ? {
    options: state.components.dropdowns.hearingCoordinators.options,
    isFetching: state.components.dropdowns.hearingCoordinators.isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingCoordinatorDropdown);
