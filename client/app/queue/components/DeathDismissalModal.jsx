import * as React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import {
  resetErrorMessages,
  showErrorMessage,
  showSuccessMessage,
  resetSuccessMessages,
  requestSave
} from '../uiReducer/uiActions';
import COPY from '../../../COPY.json';
import { fullWidth } from '../constants';
import { withRouter } from 'react-router-dom';
import {
  appealWithDetailSelector
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import QueueFlowModal from './QueueFlowModal';

class DeathDismissalModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showFullHearingDayWarning: false
    };
  }

  submit = () => {
    return this.submitDeathDismissal();
  };

  submitDeathDismissal = () => {
    const { appeal } = this.props;
    const payload = {
      data: {}
    };

    return this.props.requestSave(`/appeals/${appeal.externalId}/death_dismissal`, payload, this.getSuccessMsg());
  }

  getSuccessMsg = () => {
    const { appeal } = this.props;

    const title = sprintf(
      COPY.DEATH_DISMISSAL_SUCCESS_TITLE,
      appeal.veteranFullName
    );
    const detail = (
      <p>
      COPY.DEATH_DISMISSAL_SUCCESS_DETAIL,
      </p>
    );

    return { title,
      detail };
  }

  render = () => {
    const { appeal } = this.props;

    /* eslint-disable camelcase */
    return (
      <QueueFlowModal
        submit={this.submit}
        validateForm={this.validateForm}
        title={COPY.DEATH_DISMISSAL_MODAL_TITLE}
        button={COPY.DEATH_DISMISSAL_MODAL_SUBMIT}
      >
        <div {...fullWidth}>
          <p>
            Marking this appeal as Death Dismissal will:
            <ul>
              <li> Cancel all active tasks in Caseflow. </li>
              <li> Assign the case in VACOLS to the OVLJ Sr. Council DVC.</li>
            </ul>
            <br />
            Continue with the Death Dismissal for <b>{appeal.veteranFullName}</b>?
          </p>
        </div>
      </QueueFlowModal>
    );
  }
}

DeathDismissalModal.propTypes = {
  appeal: PropTypes.object,
  requestSave: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  showErrorMessage,
  resetErrorMessages,
  showSuccessMessage,
  resetSuccessMessages,
  requestSave,
  onReceiveAmaTasks,
  onReceiveAppealDetails
}, dispatch);

export default (withRouter(connect(mapStateToProps, mapDispatchToProps)(DeathDismissalModal)));
