import React from 'react';
import PropTypes from 'prop-types';
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
    <HearingTypeConversionProvider initialAppeal={props.appeal}>
      <HearingTypeConversion {...props} />
    </HearingTypeConversionProvider>
  );
};

HearingTypeConversionContainer.propTypes = {
  appeal: PropTypes.object,
  appealId: PropTypes.string,
  deleteAppeal: PropTypes.func,
  showErrorMessage: PropTypes.func,
  showSuccessMessage: PropTypes.func,
  task: PropTypes.object,
  taskId: PropTypes.string,
  type: PropTypes.oneOf(['Virtual']),
  history: PropTypes.object,
  userIsVsoEmployee: PropTypes.bool
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
