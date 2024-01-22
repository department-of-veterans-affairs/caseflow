/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import ApiUtil from '../../../../../util/ApiUtil';
import CorrespondencePaginationWrapper from '../../../CorrespondencePaginationWrapper';
import AddLetter from '../AddCorrespondence/AddLetter';
import {
  loadCurrentCorrespondence,
  loadCorrespondences,
  loadVeteranInformation,
  updateRadioValue,
  saveCheckboxState,
  clearCheckboxState,
  setResponseLetters
} from '../../../correspondenceReducer/correspondenceActions';

const RELATED_NO = '0';
const RELATED_YES = '1';

class AddCorrespondenceView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      veteran_id: '',
      va_date_of_receipt: '',
      source_type: '',
      package_document_type: '',
      correspondence_type_id: '',
      notes: '',
      selectedCheckboxes: []
    };
  }

  // grabs correspondences and loads into intakeCorrespondence redux store.
  getRowObjects(correspondenceUuid) {
    return ApiUtil.get(`/queue/correspondence/${correspondenceUuid}/intake?json`).then((response) => {
      const returnedObject = response.body;
      const currentCorrespondence = returnedObject.currentCorrespondence;
      const correspondences = returnedObject.correspondence;
      const veteranInformation = returnedObject.veteranInformation;

      this.props.loadCurrentCorrespondence(currentCorrespondence);
      this.props.loadCorrespondences(correspondences);
      this.props.loadVeteranInformation(veteranInformation);
    }).
      catch((err) => {
        // allow HTTP errors to fall on the floor via the console.
        console.error(new Error(`Problem with GET /queue/correspondence/${correspondenceUuid}/intake?json ${err}`));
      });
  }

  componentDidMount() {
    this.getRowObjects(this.props.correspondenceUuid);
  }

  onChange = (value) => {
    this.props.updateRadioValue({ radioValue: value });
    this.props.onContinueStatusChange(value === RELATED_NO);
    this.props.clearCheckboxState();
  }

  onChangeCheckbox = (correspondence, isChecked) => {
    this.props.saveCheckboxState(correspondence, isChecked);
    let selectedCheckboxes = this.props.checkboxes;

    if (isChecked) {
      selectedCheckboxes.push(correspondence.id);
    } else {
      selectedCheckboxes = selectedCheckboxes.filter((checkboxId) => checkboxId !== correspondence.id);
    }

    const isAnyCheckboxSelected = selectedCheckboxes.length > 0;

    this.props.onCheckboxChange(isAnyCheckboxSelected);

  }

  getKeyForRow = (index, { id }) => {
    return `${id}`;
  };

  // eslint-disable-next-line max-statements
  getDocumentColumns = (correspondence) => {
    return [
      {
        cellClass: 'checkbox-column',
        valueFunction: () => (
          <Checkbox
            name={correspondence.id.toString()}
            id={correspondence.id.toString()}
            hideLabel
            defaultValue={this.props.checkboxes.some((el) => el.id === correspondence.id)}
            onChange={(checked) => this.onChangeCheckbox(correspondence, checked)}
          />
        ),
      },
      {
        cellClass: 'va-dor-column',
        ariaLabel: 'va-dor-header-label',
        header: (
          <div id="va-dor-header">
            <span id="va-dor-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
        valueFunction: () => {
          const date = new Date(correspondence.va_date_of_receipt);

          return (
            <span className="va-dor-item">
              <p>{date.toLocaleDateString('en-US')}</p>
            </span>
          );
        }
      },
      {
        cellClass: 'source-type-column',
        ariaLabel: 'source-type-header-label',
        header: (
          <div id="source-type-header">
            <span id="source-type-header-label" className="table-header-label">
              Source Type
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-source-type-item">
            <p>{correspondence.source_type}</p>
          </span>
        )
      },
      {
        cellClass: 'package-document-type-column',
        ariaLabel: 'package-document-type-header-label',
        header: (
          <div id="package-document-type-header">
            <span id="package-document-type-header-label" className="table-header-label">
              Package Document Type
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-package-document-type-item">
            <p>{correspondence.package_document_type_id}</p>
          </span>
        )
      },
      {
        cellClass: 'correspondence-type-column',
        ariaLabel: 'correspondence-type-header-label',
        header: (
          <div id="correspondence-type-header">
            <span id="correspondence-type-header-label" className="table-header-label">
              Correspondence Type
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-correspondence-type-item">
            <p>{correspondence.correspondence_type_id}</p>
          </span>
        )
      },
      {
        cellClass: 'notes-column',
        ariaLabel: 'notes-header-label',
        header: (
          <div id="notes-header">
            <span id="notes-header-label" className="table-header-label">
              Notes
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-notes-item">
            <p>{correspondence.notes}</p>
          </span>
        )
      },
    ];
  };

  render() {
    const priorMailAnswer = [
      { displayText: 'Yes',
        value: RELATED_YES },
      { displayText: 'No',
        value: RELATED_NO }
    ];

    return (
      <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
        <h1 style={{ marginBottom: '20px' }}>Add Related Correspondence</h1>
        <p style={{ marginTop: '0px' }}>Add any related correspondence to the mail package that is in progress.</p>
        <h2 style={{ margin: '30px auto 20px auto' }}>Response Letter</h2>
        {/* add letter here */}
        <AddLetter />
        <hr style={{ borderTop: '1px solid #d6d7d9' }} />
        <h2 style={{ margin: '30px auto 20px auto' }}>Associate with prior Mail</h2>
        <p style={{ marginTop: '0px', marginBottom: '-7px' }}>Is this correspondence related to prior mail?</p>
        <RadioField style={{}}
          name=""
          options={priorMailAnswer}
          value={this.props.radioValue}
          onChange={this.onChange} />
        {this.props.radioValue === RELATED_YES && (
          <div className="cf-app-segment cf-app-segment--alt">
            <p>Please select the prior mail to link to this correspondence</p>
            {/* <p>Viewing {this.props.correspondences.length} out of {this.props.correspondences.length} total</p> */}
            <div>
              <CorrespondencePaginationWrapper
                columns={this.getDocumentColumns}
                columnsToDisplay={15}
                rowObjects={this.props.correspondences}
                summary="Correspondence list"
                className="correspondence-table"
                headerClassName="cf-correspondence-list-header-row"
                bodyClassName="cf-correspondence-list-body"
                tbodyId="correspondence-table-body"
                getKeyForRow={this.getKeyForRow}
              />

            </div>
          </div>
        )}
      </div>
    );
  }
}

AddCorrespondenceView.propTypes = {
  correspondence: PropTypes.arrayOf(PropTypes.object),
  featureToggles: PropTypes.object,
  correspondenceUuid: PropTypes.string,
  loadVeteranInformation: PropTypes.func,
  loadCurrentCorrespondence: PropTypes.func,
  loadCorrespondences: PropTypes.func,
  updateRadioValue: PropTypes.func,
  radioValue: PropTypes.string,
  saveCheckboxState: PropTypes.func,
  correspondences: PropTypes.array,
  onContinueStatusChange: PropTypes.func,
  onCheckboxChange: PropTypes.func.isRequired,
  clearCheckboxState: PropTypes.func.isRequired,
  checkboxes: PropTypes.array,
  setResponseLetters: PropTypes.func,
  currentLetters: PropTypes.number
};

const mapStateToProps = (state) => ({
  currentCorrespondence: state.intakeCorrespondence.currentCorrespondence,
  veteranInformation: state.intakeCorrespondence.veteranInformation,
  correspondences: state.intakeCorrespondence.correspondences,
  radioValue: state.intakeCorrespondence.radioValue,
  checkboxes: state.intakeCorrespondence.relatedCorrespondences,
  currentLetters: state.intakeCorrespondence.responseLetters,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    loadCurrentCorrespondence,
    loadCorrespondences,
    loadVeteranInformation,
    updateRadioValue,
    saveCheckboxState,
    clearCheckboxState,
    setResponseLetters
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AddCorrespondenceView);
