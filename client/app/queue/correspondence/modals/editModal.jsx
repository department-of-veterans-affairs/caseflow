import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import { validateDateNotInFuture } from '../../../intake/util/issues';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateCmpInformation } from '../correspondenceReducer/reviewPackageActions';
import moment from 'moment';
/* eslint-disable camelcase, max-len */
class EditModal extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      VADORDate: '',
      packageDocument: '',
      dateError: '',
      showEditModal: false,
      packageOptions: '',
      defaultVADORDate: '',
      defaultPackageDocument: '',
      saveButtonDisabled: true,
      isVaDorReadOnly: true
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
    setTimeout(this.getCorrespondenceData, 0);
  }

  getCorrespondenceData = async() => {
    const locationPath = location.pathname.split('/');
    const correspondenceId = locationPath[3];

    await ApiUtil.get(`/queue/correspondence/${correspondenceId}`).then((response) => {

      const formattedVADORDate = moment.utc(response.body.correspondence?.va_date_of_receipt).format('YYYY-MM-DD');
      const packageDocumentTypeName = { label: response.body.package_document_type?.name, value: response.body.package_document_type?.id };

      if (response.body.user_can_edit_vador) {
        this.setState({
          isVaDorReadOnly: false
        });
      }

      this.setState({
        VADORDate: formattedVADORDate,
        packageDocument: packageDocumentTypeName,
        defaultVADORDate: formattedVADORDate,
        defaultPackageDocument: packageDocumentTypeName
      });
    });
  }

  onClickEditCMP = () => {
    this.setState({ showEditModal: true });
  };

  onClickCancel = () => {
    this.setState({
      showEditModal: false,
      packageDocument: this.state.defaultPackageDocument,
      VADORDate: this.state.defaultVADORDate,
      saveButtonDisabled: true
    });
  };

  handleCMPSave = async(props) => {
    const locationPath = location.pathname.split('/');
    const correspondenceId = locationPath[3];

    const {
      VADORDate,
      packageDocument
    } = props.state;

    await ApiUtil.put(`/queue/correspondence/${correspondenceId}/update_cmp`, { data: { packageDocument, VADORDate } }).
      then((response) => {
        if (response.status === 200) {
          this.props.updateCmpInformation(packageDocument, VADORDate);
          props.onClickCancel();
          setTimeout(this.getCorrespondenceData, 0);
        }
      });
  }

  getModalButtons() {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: 'Cancel',
        onClick: this.onClickCancel
      },
      {
        classNames: ['usa-button', 'add-issue'],
        name: 'Save',
        onClick: this.handleCMPSave.bind(this, this),
        disabled: this.state.saveButtonDisabled || this.requiredFieldsMissing() || Boolean(this.state.dateError)
      }
    ];

    return btns;
  }

  requiredFieldsMissing() {
    const {
      VADORDate,
      packageDocument
    } = this.state;

    return (
      !VADORDate ||
      !packageDocument
    );
  }

  packageDocumentOnChange = (value) => {
    this.setState({
      packageDocument: value,
      saveButtonDisabled: false
    });
  };

  VADORDateOnChange = (value) => {
    this.setState({
      VADORDate: value,
      dateError: this.errorOnVADORDate(value),
      saveButtonDisabled: false
    });
  };

  errorOnVADORDate = (value) => {
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Receipt date cannot be in the future';

      return error;
    }
  };

  getPackages = async() => {
    await ApiUtil.get('/queue/correspondence/packages').then((resp) => {
      const packageTypeOptions = _.values(ApiUtil.convertToCamelCase(resp.body.package_document_types)).map((packages) => ({
        label: packages.name,
        value: packages.id.toString()
      }));

      packageTypeOptions.sort((first, second) => (first.label - second.label));
      this.setState({ packageOptions: packageTypeOptions });
    });
  }

  render() {
    const { VADORDate, packageDocument, showEditModal } = this.state;

    return (
      <div>
        <Button
          name="Edit"
          onClick={() => this.onClickEditCMP()}
          classNames={['usa-button-primary']}
          disabled={this.props.isReadOnly}
        />
        {showEditModal && (
          <Modal buttons={this.getModalButtons()} visible closeHandler={this.onClickCancel} title="Edit CMP information">
            <div>
              <div className="va-dor">
                <DateSelector
                  name="va-dor-input"
                  label="VA DOR"
                  readOnly={this.state.isVaDorReadOnly}
                  value={VADORDate}
                  errorMessage={this.state.dateError}
                  onChange={this.VADORDateOnChange}
                  type="date"
                />
              </div>
              <br />
              <SearchableDropdown
                name="package-document-type-input"
                label="Package document type"
                placeholder="Select or enter..."
                options={this.state.packageOptions}
                value={packageDocument}
                onChange={this.packageDocumentOnChange}
              />
            </div>
          </Modal>
        )}
      </div>
    );
  }
}

EditModal.propTypes = {
  onCancel: PropTypes.func,
  updateCmpInformation: PropTypes.func,
  isReadOnly: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    updateCmpInformation
  }, dispatch)
);

export default connect(
  null,
  mapDispatchToProps
)(EditModal);
