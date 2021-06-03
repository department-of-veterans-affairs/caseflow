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

class JudgeDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getJudges, 0);
  }

  getJudges = () => {
    const { judges: { options, isFetching } } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData('judges');

    ApiUtil.get('/users?role=Judge').then((resp) => {
      const judgeOptions = _.values(ApiUtil.convertToCamelCase(resp.body.judges)).map((judge) => ({
        label: judge.fullName,
        value: judge.id.toString()
      }));

      judgeOptions.sort((first, second) => (first.label - second.label));

      this.props.onReceiveDropdownData('judges', judgeOptions);
    });
  }

  getSelectedOption = () => {
    const { value, judges: { options } } = this.props;

    return _.find(options, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const {
      optional,
      name,
      label,
      onChange,
      judges: { options, isFetching },
      readOnly,
      errorMessage,
      placeholder,
    } = this.props;

    return (
      <SearchableDropdown
        optional={optional}
        name={name}
        label={isFetching ? <LoadingLabel text="Loading judges..." /> : label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

JudgeDropdown.propTypes = {
  optional: PropTypes.bool,
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  onFetchDropdownData: PropTypes.func,
  onReceiveDropdownData: PropTypes.func.isRequired,
  judges: PropTypes.shape({
    options: PropTypes.arrayOf(PropTypes.object),
    isFetching: PropTypes.bool
  }),
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

JudgeDropdown.defaultProps = {
  name: 'vlj',
  label: COPY.DROPDOWN_LABEL_JUDGE
};

const mapStateToProps = (state) => ({
  judges: state.components.dropdowns.judges ? {
    options: state.components.dropdowns.judges.options,
    isFetching: state.components.dropdowns.judges.isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(JudgeDropdown);
