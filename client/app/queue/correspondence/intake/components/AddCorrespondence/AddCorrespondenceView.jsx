/* eslint-disable max-lines */
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Table from '../../../../../components/Table';
import Checkbox from '../../../../../components/Checkbox';
import RadioField from '../../../../../components/RadioField';
import ApiUtil from '../../../../../util/ApiUtil';
import uuid from 'uuid';

export const getRowObjects = () => {
  return ApiUtil.get(`/queue/correspondence/a9a15f84-b105-4981-92d9-ecddf7c3a03a/intake?json`).then((response) => {
    const returnedObject = response.body;
    const correspondences = returnedObject.correspondence;

  }).
    catch((err) => {
      // allow HTTP errors to fall on the floor via the console.
      console.error(new Error(`Problem with GET /queue/corresondence/a9a15f84-b105-4981-92d9-ecddf7c3a03a/intake?json ${err}`));
    });
};

class AddCorrespondenceView extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      value: '2',
      checked: false,
      veteran_id: '',
      va_date_of_receipt: '',
      source_type: '',
      package_document_type: '',
      correspondence_type_id: '',
      notes: ''
    };
  }

  onChange = (value) => {
    this.setState({
      value
    });
  }

  getKeyForRow = (index, { hasCorrespondence, id }) => {
    return hasCorrespondence ? `${id}-comment` : `${id}`;
  };

  // eslint-disable-next-line max-statements
  getDocumentColumns = (row) => {
    return [
      {
        cellClass: 'checkbox-column',
        valueFunction: () => (
          <Checkbox
            name={row.id}
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
      },
      {
        cellClass: 'source-type-column',
        ariaLabel: 'source-type-header-label',
        header: (
          <div id="source-type-header">
            <span id="source-type-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
      },
      {
        cellClass: 'package-document-type-column',
        ariaLabel: 'package-document-type-header-label',
        header: (
          <div id="package-document-type-header">
            <span id="package-document-type-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
      },
      {
        cellClass: 'correspondence-type-column',
        ariaLabel: 'correspondence-type-header-label',
        header: (
          <div id="correspondence-type-header">
            <span id="correspondence-type-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
      },
      {
        cellClass: 'notes-column',
        ariaLabel: 'notes-header-label',
        header: (
          <div id="notes-header">
            <span id="notes-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
      },
    ];
  };

  render() {
    const rowObjects = getRowObjects(
      this.props.correspondence
    );

    const priorMailAnswer = [
      { displayText: 'Yes',
        value: '1' },
      { displayText: 'No',
        value: '2' }
    ];

    return (
      <div className="cf-app-segment cf-app-segment--alt">
        <h1>Add Related Correspondence</h1>
        <p>Add any related correspondence to the mail package that is in progress.</p>
        <br></br>
        <h2>Associate with prior Mail</h2>
        <p>Is this correspondence related to prior mail?</p>
        <RadioField
          name=""
          options={priorMailAnswer}
          value={this.state.value}
          onChange={this.onChange} />
        {this.state.value === '1' && (
          <div className="cf-app-segment cf-app-segment--alt">
            <p>Please select the prior mail to link to this correspondence</p>
            <p>Viewing 1-15 out of 200 total</p>
            <div>
              <Table
                columns={this.getDocumentColumns}
                rowObjects={rowObjects}
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
  uuid: PropTypes.uuid,
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    dispatch
  );

export default connect(
  mapDispatchToProps
)(AddCorrespondenceView);
