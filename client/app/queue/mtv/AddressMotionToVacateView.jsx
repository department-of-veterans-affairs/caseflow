import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import { taskById, appealWithDetailSelector } from '../selectors';
import { MTVJudgeDisposition } from './MTVJudgeDisposition';
import { JUDGE_RETURN_TO_LIT_SUPPORT } from '../../../constants/TASK_ACTIONS';
import { submitMTVJudgeDecision } from './mtvActions';
import { taskActionData } from '../utils';

export const AddressMotionToVacateView = (props) => {
  const { task, appeal } = props;

  const { selected, options } = taskActionData(props);

  const attyOptions = options.map(({ value, label }) => ({
    label: label + (selected && value === selected.id ? ' (Orig. Attorney)' : ''),
    value
  }));

  const handleSubmit = (result) => {
    props.submitMTVJudgeDecision(result, props);
  };

  return (
    <MTVJudgeDisposition
      task={task}
      attorneys={attyOptions}
      selectedAttorney={selected}
      appeal={appeal}
      onSubmit={handleSubmit}
      returnToLitSupportLink={`${props.match.url}/${JUDGE_RETURN_TO_LIT_SUPPORT.value}`}
    />
  );
};

AddressMotionToVacateView.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object,
  submitMTVJudgeDecision: PropTypes.func,
  match: PropTypes.shape({
    url: PropTypes.string
  })
};

const mapStateToProps = (state, { match }) => {
  const { taskId, appealId } = match.params;

  return {
    task: taskById(state, { taskId }),
    appeal: appealWithDetailSelector(state, { appealId })
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      submitMTVJudgeDecision
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(AddressMotionToVacateView)
);
