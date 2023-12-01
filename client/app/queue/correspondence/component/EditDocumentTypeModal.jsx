import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateDocumentTypeName } from '../correspondenceReducer/reviewPackageActions';

import COPY from '../../../../COPY';
// import { onReceiveAmaTasks } from '../../queue/QueueActions';
// import { showErrorMessage, showSuccessMessage } from '../../uiReducer/uiActions';

// import ApiUtil from '../../util/ApiUtil';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';

class EditDocumentTypeModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      packageDocument: '',
      dateError: '',
      disabledSaveButton: true,
      packageOptions: '',
      loading: false
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
  }

  getPackages = () => {
    ApiUtil.get('/queue/correspondence/edit_document_type_correspondence').then((resp) => {
      const documents = resp.body.data.map((doc) => ({
        label: doc.name,
        value: doc.id.toString()
      }));
      // const documents = resp;

      this.setState({ packageOptions: documents });
    });
  }

  packageDocumentOnChange = (value) => {
    this.setState({
      packageDocument: value,
      disabledSaveButton: false
    });
  };

  render() {
    const { onCancel, document, modalState } = this.props;
    const { packageDocument } = this.state;

    const submit = async (value) => {
      this.props.updateDocumentTypeName(value, this.props.indexDoc);
    };

    return (
      <Modal
        title= {sprintf(COPY.TITLE_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={this.state.disabledSaveButton}
          onClick={submit(this.state.packageDocument)}>Save</Button>}
        cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      >
        <div>
          <p>{sprintf(COPY.TEXT_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</p>
        </div>
        <div style={{ fontWeight: 'bold' }}>
          {sprintf(COPY.ORIGINAL_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
        </div>
        <div>
          {document.documentName}

        </div>
        <br />
        <SearchableDropdown
          name = "issue-category"
          label = {sprintf(COPY.NEW_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
          strongLabel = {false}
          placeholder = "Select or enter..."
          options = {this.state.packageOptions}
          value = {packageDocument}
          onChange = {this.packageDocumentOnChange}
        />
      </Modal>
    );

  }
}

EditDocumentTypeModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  document: PropTypes.object,
  onSaveValue: PropTypes.func
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateDocumentTypeName
}, dispatch);

export default connect(
  null,
  mapDispatchToProps,
)(EditDocumentTypeModal);
