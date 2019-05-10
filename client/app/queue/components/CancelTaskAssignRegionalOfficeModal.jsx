import _ from 'lodash';
import * as React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { css } from 'glamor';

import COPY from '../../../COPY.json';
import QueueFlowModal from './QueueFlowModal';
import RegionalOfficeDropdown from '../../components/DataDropdowns/RegionalOffice';
import TextareaField from '../../components/TextareaField';
import { taskById } from '../selectors';
import { highlightInvalidFormItems } from '../uiReducer/uiActions';

class CancelTaskAssignRegionalOfficeModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      regionalOffice: null,
      notes: ''
    };
  }

  onRegionalOfficeSelected = (value) => {
    this.setState({ regionalOffice: value });
    this.props.highlightInvalidFormItems(false);
  }

  validateRegionalOfficePopulated = () => !_.isNull(this.state.regionalOffice);

  onNotesChanged = (notes) => this.setState({ notes });

  onSubmit = () => {
    // Return a future
  };

  render = () => {
    const { hasError } = this.props;

    return (
      <QueueFlowModal
        title={COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_TITLE}
        button={COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_BUTTON}
        submit={this.onSubmit}
        validateForm={this.validateRegionalOfficePopulated}
      >
        <p>
          {COPY.CANCEL_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_DETAIL}
        </p>
        <RegionalOfficeDropdown
          errorMessage={hasError ? COPY.REGIONAL_OFFICE_REQUIRED_MESSAGE : null}
          value={this.state.regionalOffice}
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

const mapStateToProps = (state, ownProps) => (
  {
    task: taskById(state, { taskId: ownProps.taskId }),
    hasError: state.ui.highlightFormItems
  }
);

const mapDispatchToProps = (dispatch) => bindActionCreators({
  highlightInvalidFormItems
}, dispatch);

export default (withRouter(
  connect(mapStateToProps, mapDispatchToProps)(
    CancelTaskAssignRegionalOfficeModal
  )
));
