import * as React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import COPY from '../../COPY';
import { requestSave, resetSuccessMessages } from './uiReducer/uiActions';
import { setOvertime } from './QueueActions';
import { appealWithDetailSelector } from './selectors';
import QueueFlowModal from './components/QueueFlowModal';

export const SetOvertimeStatusModal = (props) => {

  const { overtime, externalId } = props.appeal;

  const onCancel = () => {
    props.resetSuccessMessages();
    props.history.goBack();
  };

  const submit = () => {
    let successMsg;

    if (overtime) {
      successMsg = {
        title: sprintf(COPY.TASK_SNAPSHOT_REMOVE_OVERTIME_SUCCESS, props.appeal.veteranFullName),
        detail: COPY.TASK_SNAPSHOT_REMOVE_OVERTIME_SUCCESS_DETAIL
      };
    } else {
      successMsg = {
        title: sprintf(COPY.TASK_SNAPSHOT_MARK_AS_OVERTIME_SUCCESS, props.appeal.veteranFullName),
        detail: COPY.TASK_SNAPSHOT_MARK_AS_OVERTIME_SUCCESS_DETAIL
      };
    }

    const payload = { data: { overtime: !overtime } };

    return props.requestSave(`/appeals/${externalId}/work_mode`, payload, successMsg).
      then((resp) => {
        props.setOvertime(externalId, resp.body.work_mode.overtime);
      });
  };

  return (
    <React.Fragment>
      <QueueFlowModal
        pathAfterSubmit={`/queue/appeals/${externalId}`}
        title={overtime ? COPY.TASK_SNAPSHOT_REMOVE_OVERTIME_HEADER : COPY.TASK_SNAPSHOT_MARK_AS_OVERTIME_HEADER}
        submit={submit}
        onCancel={onCancel}>
        {overtime ? COPY.TASK_SNAPSHOT_REMOVE_OVERTIME_CONFIRMATION : COPY.TASK_SNAPSHOT_MARK_AS_OVERTIME_CONFIRMATION}
      </QueueFlowModal>
    </React.Fragment>
  );
};

SetOvertimeStatusModal.propTypes = {
  appeal: PropTypes.object,
  externalId: PropTypes.string,
  history: PropTypes.object,
  overtime: PropTypes.object,
  requestSave: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  setOvertime: PropTypes.func
};

const mapStateToProps = (state, ownProps) => ({
  appeal: appealWithDetailSelector(state, ownProps)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  resetSuccessMessages,
  setOvertime
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SetOvertimeStatusModal));

