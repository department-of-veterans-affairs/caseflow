import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import SearchableDropdown from 'app/components/SearchableDropdown';

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
      showEditModal: false,
      packageOptions: '',
      loading: false
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
  }

  getPackages = () => {
    ApiUtil.get('/queue/correspondence/getTypo').then((resp) => {
      const documents = resp.body.allDocuments.map((doc) => ({
        label: doc.name,
        value: doc.id.toString()
      }));

      this.setState({ packageOptions: documents });
    });
  }

  packageDocumentOnChange = (value) => {
    this.setState({
      packageDocument: value
    });
  };

  render() {
    // const [loading] = useState(false);
    const { modalState, onCancel, document } = this.props;
    const disable = true;
    const { packageDocument } = this.state;

    const submit = async () => {
      return 0;
    };

    return (
      <Modal
        title= {sprintf(COPY.TITLE_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={disable} onClick={submit}>Save</Button>}
        cancelButton={<Button linkStyling disabled={this.loading} onClick={onCancel}>Cancel</Button>}
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
          name="issue-category"
          label="Package document type"
          strongLabel = {false}
          placeholder="Select or enter..."
          options={this.state.packageOptions}
          value={packageDocument}
          onChange={this.packageDocumentOnChange}
        />

      </Modal>
    );

  }
}

EditDocumentTypeModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  document: PropTypes.object,
};

export default EditDocumentTypeModal;
