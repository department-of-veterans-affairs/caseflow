import React from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateDocumentTypeName, setCorrespondence } from '../correspondenceReducer/reviewPackageActions';
import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';

class EditDocumentTypeModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      packageDocument: null,
      disabledSaveButton: true,
      packageOptions: {},
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
  }

  getPackages = () => {
    ApiUtil.get('/queue/correspondence/edit_document_type_correspondence').then((resp) => {
      const documents = resp.body.data.map((doc) => ({
        label: doc.name,
        value: doc.id
      }));

      this.setState({ packageOptions: documents });
    });
  }

  packageDocumentOnChange = (value) => {
    this.setState({
      packageDocument: value,
      disabledSaveButton: false
    });
  };

  updateDocumentType = async () => {
    try {
      ApiUtil.patch(`/queue/correspondence/${this.props.document.id}/update_document`, {
        data: {
          vbms_document_type_id: this.state.packageDocument.value
        }
      }).then((resp) => {
        this.props.setCorrespondence(resp.body.correspondence);
      });
      this.props.updateDocumentTypeName(this.state.packageDocument, this.props.indexDoc);
      this.props.setModalState(false);
    } catch (error) {
      console.error(error);
    }
  }

  render() {
    const { onCancel, document } = this.props;
    const { packageDocument } = this.state;

    const submit = () => {
      this.updateDocumentType();
    };
    const originalDocumentTitle = document.document_title;

    return (
      <Modal
        title= {sprintf(COPY.TITLE_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
        closeHandler={onCancel}
        confirmButton={<Button disabled={this.state.disabledSaveButton}
          onClick={submit}>Save</Button>}
        cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
      >
        <p>{sprintf(COPY.TEXT_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</p>
        <div className="modal-fwb">
          {sprintf(COPY.ORIGINAL_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
        </div>
        <p>{originalDocumentTitle}</p>
        <div className="correspondence-doctype-edit-dropdown">
          <SearchableDropdown
            name = "issue-category"
            label = {sprintf(COPY.NEW_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
            strongLabel = {false}
            placeholder = "Type to search..."
            options = {this.state.packageOptions}
            value = {packageDocument}
            onChange = {this.packageDocumentOnChange}
          />
        </div>
      </Modal>
    );
  }
}

EditDocumentTypeModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  document: PropTypes.object,
  onSaveValue: PropTypes.func,
  updateDocumentTypeName: PropTypes.func,
  setCorrespondence: PropTypes.func,
  setModalState: PropTypes.func,
  indexDoc: PropTypes.number
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateDocumentTypeName,
  setCorrespondence
}, dispatch);

export default connect(
  null,
  mapDispatchToProps,
)(EditDocumentTypeModal);
