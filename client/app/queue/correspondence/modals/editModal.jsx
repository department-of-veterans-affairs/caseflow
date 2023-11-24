import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import { validateDateNotInFuture } from '../../../intake/util/issues';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';

class EditModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      VADORDate: '',
      packageDocument: '',
      dateError: '',
      showEditModal: false,
      packageOptions: ''
    };
  }

  componentDidMount() {
    setTimeout(this.getPackages, 0);
  }

  onClickEditCMP = () => {
    this.setState({ showEditModal: true });
  };

  onClickCancel = () => {
    this.setState({
      showEditModal: false,
      packageDocument: '',
      VADORDate: ''
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
        value: packages.id.toString()
      }));

      packageTypeOptions.sort((first, second) => (first.label - second.label));
      this.setState({ packageOptions: packageTypeOptions });
    });
  }

  render() {
    // const { onCancel } = this.props;
    const { VADORDate, packageDocument, showEditModal } = this.state;

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
                  value={VADORDate}
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
};

export default EditModal;
