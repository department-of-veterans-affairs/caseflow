import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import COPY from '../../../COPY.json';
import QueueFlowModal from './QueueFlowModal';
import RegionalOfficeDropdown from '../../components/DataDropdowns/RegionalOffice';
import TextareaField from '../../components/TextareaField';

class CancelTaskAssignRegionalOfficeModal extends React.Component {
  onRegionalOfficeSelected = (value, label) => {
  };

  onNotesChanged = (notes) => {
  };

  render = () => {
    return (
      <QueueFlowModal
        title={COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_TITLE}
        button={COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_BUTTON}
      >
        <p>
          {COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_DETAIL}
        </p>
        <RegionalOfficeDropdown
          onChange={this.onRegionalOfficeSelected}
        />
        <TextareaField
          label="Notes"
          strongLabel
          textAreaStyling={css({ height: '100px' })}
          onChange={this.onNotesChanged}
        />
      </QueueFlowModal>
    );
  }
}

const mapStateToProps = (state, ownProps) => {
  return { ...ownProps };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CancelTaskAssignRegionalOfficeModal
  )
));
