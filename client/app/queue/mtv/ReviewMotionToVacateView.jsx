import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { MTVAttorneyDisposition } from './MTVAttorneyDisposition';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';

import { taskById } from '../selectors';

const handleSubmit = (review) => {
  console.log('handleSubmit', review);
};

export const ReviewMotionToVacateView = ({ task }) => {
  return <MTVAttorneyDisposition task={task} onSubmit={handleSubmit} />;
};

ReviewMotionToVacateView.propTypes = {
  task: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
  return {
    task: taskById(state, { taskId: ownProps.taskId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(MTVAttorneyDisposition)
);
