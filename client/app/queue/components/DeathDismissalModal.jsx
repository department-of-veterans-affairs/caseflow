import * as React from 'react';
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
import { formatDateStr } from '../../util/DateUtil';
import ApiUtil from '../../util/ApiUtil';
import { withRouter } from 'react-router-dom';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import {
  appealWithDetailSelector,
  scheduleHearingTasksForAppeal
} from '../selectors';
import { onReceiveAmaTasks, onReceiveAppealDetails } from '../QueueActions';
import { prepareAppealForStore } from '../utils';
import _ from 'lodash';
import QueueFlowModal from './QueueFlowModal';
import Alert from '../../components/Alert';

class DeathDismissalModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showErrorMessages: false,
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

    return this.props.requestSave(`/appeals/${appeal.externalId}/death_dismissal`, payload, this.getSuccessMsg())
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
    )

    return { title,
      detail };
  }

  render = () => {
    const { appeal } = this.props;
    const { showErrorMessages } = this.state;

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
            <br/>
            Continue with the Death Dismissal for <b>{appeal.veteranFullName}</b>?
          </p>
        </div>
      </QueueFlowModal>
    );
  }
}

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps),
  saveState: state.ui.saveState.savePending,
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
