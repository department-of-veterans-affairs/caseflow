import React from 'react';
import PropTypes from 'prop-types';
import { PencilIcon } from '../../../../../components/icons/PencilIcon';
import Button from '../../../../../components/Button';
import { useSelector } from 'react-redux';
import CorrespondenceDetailsTable from './CorrespondenceDetailsTable';
import ConfirmTasksNotRelatedToAnAppeal from './ConfirmTasksNotRelatedToAnAppeal';
import Table from '../../../../../components/Table';
import ConfirmTasksRelatedToAnAppeal from './ConfirmTasksRelatedToAnAppeal';
import { formatDateStr } from 'app/util/DateUtil';

export const ConfirmCorrespondenceView = (props) => {

  const checkedMailTasks = props.mailTasks;
  const intakeCorrespondence = useSelector((state) => state.intakeCorrespondence);
  const relatedCorrespondences = intakeCorrespondence.relatedCorrespondences;
  const responseLetters = intakeCorrespondence.responseLetters;

  let correspondenceTable = null;
  let mailTaskTable = null;

  // eslint-disable-next-line max-statements
  const getDocumentColumns = (correspondence) => {

    return [
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

  if (relatedCorrespondences.length === 0) {
    correspondenceTable =
    <div className= "associated-prior-mail-empty"> Correspondence is not related to prior mail </div>;
  } else {

    correspondenceTable = <Table
      className= "table-latitude"
      columns={getDocumentColumns}
      rowObjects={relatedCorrespondences}
    />;
  }

  if (checkedMailTasks.length === 0) {
    mailTaskTable = <div className= "completed-mail-tasks-empty"></div>;
  } else {
    mailTaskTable = checkedMailTasks.map((name, index) => (
      <ul key={index} className="completed-mail-tasks">

        <li>{name}</li>

      </ul>
    ));
  }

  return (
    <div className="confirm-correspondence-view-border corr">
      <h1 className="corr-h1">Review and Confirm Correspondence</h1>
      <p className="p-review-and-confirm">
        Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <CorrespondenceDetailsTable correspondence={props.correspondence} />
      <div>
        <div className="corr-flex">
          <h2 className="corr-h2">Response Letters</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(1)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit section</span>
            </Button>
          </div>
        </div>
        <div className="correspondence-letters-table-container" >
          <div className="correspondence-letters-table">
            <table className="correspondence-response-letters-table">
              <tbody>
                <tr>
                  <th className="cf-txt-c"> Date Sent </th>
                  <th className="cf-txt-c"> Letter Type </th>
                  <th className="cf-txt-c"> Letter Title </th>
                  <th className="cf-txt-c"> Letter Subcategory </th>
                  <th className="cf-txt-c"> Letter Subcategory Reasons</th>
                  <th className="cf-txt-c"> Response Window </th>
                </tr>
              </tbody>
              { Object.keys(responseLetters)?.map((indexValue) => {
                const responseLetter = responseLetters[indexValue];
                const responseDate = new Date(responseLetter?.date).toISOString();

                return (
                  <tbody key={indexValue}>
                    <tr>
                      <td> {formatDateStr(responseDate)} </td>
                      <td> {responseLetter?.type} </td>
                      <td> {responseLetter?.title} </td>
                      <td> {responseLetter?.subType} </td>
                      <td> {responseLetter?.reason} </td>
                      <td>
                        {
                          (responseLetter?.customValue === '' || responseLetter?.customValue === null) ?
                           responseLetter?.responseWindows :
                            `${responseLetter?.customValue } days`
                        }
                      </td>
                    </tr>
                  </tbody>
                );
              })}
            </table>
          </div>
        </div>
      </div>
      <div>
        <div className="corr-flex">
          <h2 className="corr-h2">Associated Prior Mail</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(1)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit section</span>
            </Button>
          </div>
        </div>
        <div className= "review-and-confirm-title-div-color">
          <div className="review-and-confirm-title-div-style">
            {correspondenceTable}
          </div>
        </div>
      </div>
      <div>
        <div className="corr-flex">
          <h2 className="corr-h2">Completed Mail Tasks</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(2)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit section</span>
            </Button>
          </div>
        </div>
        <div className="review-and-confirm-title-div-style">
          <div className="completed-mail-tasks-title">
            Completed Mail Tasks
          </div>
          {mailTaskTable}
        </div>
      </div>
      <div>
        <div className="corr-flex">
          <h2 className="corr-h2">Linked Appeals & New Tasks</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(2)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit section</span>
            </Button>
          </div>
        </div>
        <ConfirmTasksRelatedToAnAppeal />

        <div className="corr-flex">
          <h2 className="corr-h2">Tasks not related to an Appeal</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(2)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit section</span>
            </Button>
          </div>
        </div>
        <ConfirmTasksNotRelatedToAnAppeal />
      </div>
    </div>
  );
};

ConfirmCorrespondenceView.propTypes = {
  goToStep: PropTypes.func,
  correspondence: PropTypes.object,
  mailTasks: PropTypes.arrayOf(PropTypes.string)
};
export default ConfirmCorrespondenceView;
