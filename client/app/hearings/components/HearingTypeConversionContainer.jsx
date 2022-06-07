import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';

import { appealWithDetailSelector, taskById } from '../../queue/selectors';
import { deleteAppeal } from '../../queue/QueueActions';
import {
  showErrorMessage,
  showSuccessMessage,
} from '../../queue/uiReducer/uiActions';

import { HearingTypeConversion } from './HearingTypeConversion';
import { HearingTypeConversionProvider } from '../contexts/HearingTypeConversionContext';

const HearingTypeConversionContainer = (props) => {
  return (
    <HearingTypeConversionProvider appeal={props.appeal}>
      <HearingTypeConversion {...props} />
    </HearingTypeConversionProvider>
  );
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  task: taskById(state, { taskId: ownProps.taskId }),
  userIsVsoEmployee: state.ui.userIsVsoEmployee,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      deleteAppeal,
      showErrorMessage,
      showSuccessMessage,
    },
    dispatch
  );

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(HearingTypeConversionContainer)
);
