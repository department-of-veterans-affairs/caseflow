import React from 'react';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import COPY from '../../../../COPY';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  setBatchAutoAssignmentAttemptId,
  setAutoAssignButtonDisabled
} from '../correspondenceReducer/reviewPackageActions';

const BatchAutoAssignButton = (props) => {
  const handleAutoAssign = async () => {
    try {
      props.setAutoAssignButtonDisabled(true);
      const response = await ApiUtil.get('/queue/correspondence/auto_assign_correspondences');
      const data = await response.body;

      props.setBatchAutoAssignmentAttemptId(data.batch_auto_assignment_attempt_id);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
      <Button
        onClick={handleAutoAssign}
        ariaLabel="Auto assign correspondences"
        disabled={props.disabled}
      >
        {COPY.AUTO_ASSIGN_CORRESPONDENCES_BUTTON}
      </Button>
    </div>
  );
};

BatchAutoAssignButton.propTypes = {
  disabled: PropTypes.bool,
  setBatchAutoAssignmentAttemptId: PropTypes.func,
  setAutoAssignButtonDisabled: PropTypes.func
};

const mapStateToProps = (state) => ({
  disabled: state.reviewPackage.autoAssign.isButtonDisabled
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setBatchAutoAssignmentAttemptId,
    setAutoAssignButtonDisabled
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(BatchAutoAssignButton);
