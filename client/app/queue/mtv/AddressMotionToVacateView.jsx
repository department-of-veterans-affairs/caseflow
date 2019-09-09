import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import { taskById, appealWithDetailSelector } from '../selectors';
import { MTVJudgeDisposition } from './MTVJudgeDisposition';
import { submitMTVJudgeDecision } from './mtvActions';

export const AddressMotionToVacateView = (props) => {
  const { task, appeal, attorneysOfJudge } = props;

  const attyOptions = Object.values(attorneysOfJudge).map(({ id, display_name }) => ({
    label: display_name,
    value: id
  }));

  const handleSubmit = (decision) => {
    props.submitMTVJudgeDecision(decision);
  };

  useEffect(() => {
    if (!attyOptions.length) {
      // dispatch to populate attys
    }
  });

  return (
    attorneysOfJudge && (
      <MTVJudgeDisposition task={task} attorneys={attyOptions} appeal={appeal} onSubmit={handleSubmit} />
    )
  );
};

AddressMotionToVacateView.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object,
  attorneysOfJudge: PropTypes.array,
  fetchJudges: PropTypes.func
};

const mapStateToProps = (state, ownProps) => {
  const {
    queue: { attorneysOfJudge }
  } = state;

  return {
    task: taskById(state, { taskId: ownProps.taskId }),
    appeal: appealWithDetailSelector(state, ownProps),
    attorneysOfJudge
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
