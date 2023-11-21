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

class EditModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      VADORDate: '',
      packageDocument: {},
      dateError: '',
      showEditModal: false,
      packageOptions: ''
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
  }

  onClickEditCMP = () => {
    this.setState({
      showEditModal: true,
      packageDocument: {
        value: this.props.packageDocumentType.value,
        label: this.props.packageDocumentType.label
      },
      VADORDate: moment.utc(this.props.VADORDate).format('YYYY-MM-DD')
    });
  };

  onClickCancel = () => {
    this.setState({
      showEditModal: false,
      packageDocument: this.state.packageDocument,
      VADORDate: this.state.VADORDate
    });
  };

  handleCMPSave = async(props) => {
    const {
      VADORDate,
      packageDocument
    } = props.state;

    await ApiUtil.put(`/queue/correspondence/${this.props.correspondence_uuid}/update_cmp`, { data: { packageDocument, VADORDate } }).
      then((response) => {
        if (response.status === 200) {
          this.props.updateCmpInformation(packageDocument, VADORDate);
          props.onClickCancel();
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
        disabled: this.requiredFieldsMissing() || Boolean(this.state.dateError)
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
      packageDocument: value
    });
  };

  VADORDateOnChange = (value) => {
    this.setState({
      VADORDate: value,
      dateError: this.errorOnVADORDate(value)
    });
  };

  errorOnVADORDate = (value) => {
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';

      return error;
    }
  };

  getPackages = () => {
    ApiUtil.get('/queue/correspondence/packages').then((resp) => {
      /* eslint-disable-next-line max-len */
      const packageTypeOptions = _.values(ApiUtil.convertToCamelCase(resp.body.package_document_types)).map((packages) => ({
        label: packages.name,
        value: packages.id
      }));

      packageTypeOptions.sort((first, second) => (first.id - second.id));
      this.setState({ packageOptions: packageTypeOptions });
    });
  }

  render() {
    // const { onCancel } = this.props;
    const { showEditModal } = this.state;

    return (
      <div>
        <Button
          name="Edit"
          onClick={() => this.onClickEditCMP()}
          classNames={['usa-button-primary']}
        />
        {showEditModal && (
          <Modal
            buttons={this.getModalButtons()}
            visible closeHandler={this.onClickCancel}
            title="Edit CMP information"
          >
            <div className="add-nonrating-request-issue">
              <div className="decision-date">
                <DateSelector
                  name="decision-date"
                  label="VA DOR"
                  strongLabel
                  value={this.state.VADORDate}
                  errorMessage={this.state.dateError}
                  onChange={this.VADORDateOnChange}
                  type="date"
                />
              </div>
              <br />
              <SearchableDropdown
                name="issue-category"
                label="Package document type"
                strongLabel
                placeholder="Select or enter..."
                options={this.state.packageOptions}
                value={this.props.packageDocumentType.value}
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
  VADORDate: PropTypes.string,
  correspondence_uuid: PropTypes.string,
  packageDocumentType: PropTypes.object,
  updateCmpInformation: PropTypes.func
};

const mapStateToProps = (state) => ({
  correspondence_uuid: state.reviewPackage.correspondence.uuid,
  VADORDate: state.reviewPackage.correspondence.va_date_of_receipt,
  packageDocumentType: {
    value: state.reviewPackage.packageDocumentType?.id,
    label: state.reviewPackage.packageDocumentType?.name
  }
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    updateCmpInformation
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(EditModal);
