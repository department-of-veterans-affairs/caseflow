/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import CorrespondencePaginationWrapper from '../../../CorrespondencePaginationWrapper';
import {
  updateRadioValue,
  saveCheckboxState,
  clearCheckboxState
} from '../../../correspondenceReducer/correspondenceActions';

const RELATED_NO = '0';
const RELATED_YES = '1';

class AddCorrespondenceView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      veteranId: '',
      vaDateOfReceipt: '',
      sourceType: '',
      packageDocumentType: '',
      correspondenceType: '',
      notes: '',
      selectedCheckboxes: []
    };
  }

  onChange = (value) => {
    this.props.updateRadioValue({ radioValue: value });
    this.props.onContinueStatusChange(value === RELATED_NO);
    this.props.clearCheckboxState();
  }

  onChangeCheckbox = (correspondence, isChecked) => {
    this.props.saveCheckboxState(correspondence, isChecked);
    let selectedCheckboxes = [...this.props.checkboxes];

    if (isChecked) {
      selectedCheckboxes.push(correspondence);
    } else {
      selectedCheckboxes = selectedCheckboxes.filter((checkbox) => checkbox.id !== correspondence.id);
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
          <div className="checkbox-column-inline-style">
            <Checkbox
              name={correspondence.id.toString()}
              id={correspondence.id.toString()}
              hideLabel
              defaultValue={this.props.checkboxes.some((el) => el.id === correspondence.id)}
              onChange={(checked) => this.onChangeCheckbox(correspondence, checked)}
            />
          </div>
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
          const date = new Date(correspondence.vaDateOfReceipt);

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
            <p>{correspondence.sourceType}</p>
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
            <p>{correspondence.packageDocumentType}</p>
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
            <p>{correspondence.correspondenceType}</p>
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
      <div className="add-related-correspondence corr">
        <h1 className="a-r-h1">Add Related Correspondence</h1>
        <p className="a-r-p1">Add any related correspondence to the mail package that is in progress.</p>
        <h2 className="a-r-h2">Associate with prior Mail</h2>
        <p className="a-r-p2">Is this correspondence related to prior mail?</p>
        <RadioField
          name=""
          options={priorMailAnswer}
          value={this.props.radioValue}
          onChange={this.onChange} />
        {this.props.radioValue === RELATED_YES && (
          <div className="cf-app-segment cf-app-segment--alt">
            <p>Please select the prior mail to link to this correspondence</p>
            <div>
              <CorrespondencePaginationWrapper
                columns={this.getDocumentColumns}
                columnsToDisplay={15}
                rowObjects={this.props.priorMail}
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
  correspondence: PropTypes.object,
  priorMail: PropTypes.arrayOf(PropTypes.object),
  featureToggles: PropTypes.object,
  correspondenceUuid: PropTypes.string,
  updateRadioValue: PropTypes.func,
  radioValue: PropTypes.string,
  saveCheckboxState: PropTypes.func,
  onContinueStatusChange: PropTypes.func,
  onCheckboxChange: PropTypes.func.isRequired,
  clearCheckboxState: PropTypes.func.isRequired,
  checkboxes: PropTypes.array
};

const mapStateToProps = (state) => ({
  radioValue: state.intakeCorrespondence.radioValue,
  checkboxes: state.intakeCorrespondence.relatedCorrespondences,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    updateRadioValue,
    saveCheckboxState,
    clearCheckboxState
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AddCorrespondenceView);
