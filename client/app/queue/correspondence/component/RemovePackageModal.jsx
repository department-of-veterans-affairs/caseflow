import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import StringUtil from '../../../util/StringUtil';
// import { connect } from 'react-redux';
// import { bindActionCreators } from 'redux';
// import { updateDocumentTypeName } from '../correspondenceReducer/reviewPackageActions';
import TextareaField from '../../../components/TextareaField';
import RadioField from '../../../components/RadioField';
// import { css } from 'glamor';
import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import { Redirect } from 'react-router-dom';

class RemovePackageModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      reasonForRemove: null,
      disabledSaveButton: true,
      reasonReject: ''
    };
  }

  handleSelect(reasonForRemove) {
    this.setState({ reasonForRemove });
  }

  reasonChange = (value) => {
    if (value.trim().length > 0) {
      this.setState({
        reasonReject: value,
        disabledSaveButton: false
      });
    } else {
      this.setState({
        reasonReject: '',
        disabledSaveButton: true
      });
    }
  }

  removePackage = async () => {
    try {
      ApiUtil.post(`/queue/correspondence/${this.props.correspondence_id}/remove_package`, {
      });

      return <Redirect to="/queue/correspondence" />;
      // this.props.updateDocumentTypeName(this.state.packageDocument, this.props.indexDoc);
      // this.props.setModalState(false);
    } catch (error) {
      console.error(error);
    }
  }

  render() {
    const { onCancel } = this.props;
    const submit = () => {
      this.removePackage();
    };

    const removeReasonOptions = [
      { displayText: 'Approve request',
        value: 'Approve request' },
      { displayText: 'Reject request',
        value: 'Reject request' }
    ];

    return (
      <Modal
        title= {sprintf(COPY.CORRESPONDENCE_HEADER_REMOVE_PACKAGE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={this.state.disabledSaveButton}
          onClick={submit}>Confirm</Button>}
        cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      >
        <p>
          <span style= {{ fontWeight: 'bold' }}>{sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE)}</span>
          {StringUtil.nl2br(COPY.CORRRESPONDENCE_TEXT_REMOVE_PACKAGE)}
        </p>

        <RadioField
          vertical
          label= {sprintf(COPY.CORRRESPONDENCE_LABEL_OPTION_REMOVE_PACKAGE)}
          name="merge-package"
          value={this.state.reasonForRemove}
          options={removeReasonOptions}
          onChange={(val) => this.handleSelect(val)}
        />

        {this.state.reasonForRemove &&
              <TextareaField
                name={sprintf(COPY.CORRESPONDENCE_TITLE_REMOVE_PACKAGE_REASON_REJECT)}
                onChange={this.reasonChange}
                value={this.state.reasonReject}
              />
        }

      </Modal>
    );

  }
}

RemovePackageModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  setModalState: PropTypes.func,
  correspondence_id: PropTypes.number
};

export default (RemovePackageModal);
