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
    // Pull anything we need out of props and state
    // Create a payload
    const payload = {
      data: {}
    };

    return this.props.requestSave(`/appeal/${appeal.id}/death_dismissal`, payload, this.getSuccessMsg()).
      then(() => {
        history.goBack();
      }, () => {
        this.props.showErrorMessage({
          title: 'Could not mark Appeal for Death Dismissal',
          detail: 'Contact Support'
        });
      });
  }

  getSuccessMsg = () => {
    const { appeal } = this.props;

    // TODO move to copy
    const title = sprintf(
      "Veteran %s marked as Death Dismissal",
      appeal.veteranFullName
    );
    // TODO move to copy
    const detail = (
      <p>
        "Veteran marked as Death Dismissal and sent to OVLJ Sr Council DVC in VACOLs",
      </p>
    )

  }

  render = () => {
    const { appeal } = this.props;
    const { showErrorMessages } = this.state;

    /* eslint-disable camelcase */
    return (
      <QueueFlowModal
        submit={this.submit}
        validateForm={this.validateForm}
        title="FNOD Death Dismissal"
        button="Submit Death Dismissal"
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
