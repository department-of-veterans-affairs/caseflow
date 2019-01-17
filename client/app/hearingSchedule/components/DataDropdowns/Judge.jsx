import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from './actions';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../../../components/SearchableDropdown';

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
        value: judge.id
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
    const { name, label, onChange, judges: { options }, readOnly } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value)}
        options={options} />
    );
  }
}

JudgeDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.number,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool
};

JudgeDropdown.defaultProps = {
  name: 'vlj',
  label: 'VLJ'
};

const mapStateToProps = (state) => ({
  judges: {
    options: state.hearingDropdownData.judges.options,
    isFetching: state.hearingDropdownData.judges.isFetching
  }
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(JudgeDropdown);
