import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../SearchableDropdown';

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
    const { name, label, onChange, judges: { options }, readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value, option.label)}
        options={options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

JudgeDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

JudgeDropdown.defaultProps = {
  name: 'vlj',
  label: 'VLJ'
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
