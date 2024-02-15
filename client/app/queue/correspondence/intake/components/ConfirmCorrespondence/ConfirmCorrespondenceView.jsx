import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { PencilIcon } from '../../../../../components/icons/PencilIcon';
import Button from '../../../../../components/Button';
import { useSelector } from 'react-redux';
import CorrespondenceDetailsTable from './CorrespondenceDetailsTable';
import ConfirmTasksNotRelatedToAnAppeal from './ConfirmTasksNotRelatedToAnAppeal';
import Table from '../../../../../components/Table';
import ConfirmTasksRelatedToAnAppeal from './ConfirmTasksRelatedToAnAppeal';
import { COLORS } from '../../../../../constants/AppConstants';

const bodyStyling = css({
  '& > tr > td': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    borderBottom: 'none',
    borderColor: COLORS.GREY_LIGHT,
    paddingTop: '0vh',
    paddingBottom: '0vh',
  },
});

const tableStyling = css({
  marginBottom: '-1vh',
  marginTop: '1vh'
});

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

  if (relatedCorrespondences.length === 0) {
    correspondenceTable =
    <div {...css({
      marginBottom: '150px',
      fontWeight: 'bold'
    })}> Correspondence is not related to prior mail </div>;
  } else {

    correspondenceTable = <Table
      columns={getDocumentColumns}
      // columnsToDisplay={15}
      rowObjects={relatedCorrespondences}
      styling={tableStyling}
      bodyStyling={bodyStyling}
    />;
  }

  if (checkedMailTasks.length === 0) {
    mailTaskTable = <div {...css({
      marginBottom: '150px',
      fontWeight: 'bold'
    })}>  </div>;
  } else {
    mailTaskTable = checkedMailTasks.map((name, index) => (
      <div
        key={index}
        {...css({
          borderBottom: index === checkedMailTasks.length - 1 ? 'none' : '1px solid #d6d7d9',
          padding: '10px 10px',
          marginBottom: '10px',
        })}
      >
        <span>{name}</span>
      </div>
    ));
  }

  return (
    <div className="gray-border corr" style={{ marginBottom: '2rem' }}>
      <h1 className="corr-h1">Review and Confirm Correspondence</h1>
      <p style={{ fontSize: '.85em' }}>
        Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <CorrespondenceDetailsTable />
      <div>
        <div className="corr-flex">
          <h2 className="corr-h2">Response Letters</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(1)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit Section</span>
            </Button>
          </div>
        </div>
        <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND })}>
          <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND, paddingTop: '20px', paddingBottom: '20px' })}>
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
                const responseDate = new Date(responseLetter?.date);

                return (
                  <tbody key={indexValue}>
                    <tr>
                      <td> {responseDate?.toLocaleDateString('en-US')} </td>
                      <td> {responseLetter?.type} </td>
                      <td> {responseLetter?.title} </td>
                      <td> {responseLetter?.subType} </td>
                      <td> {responseLetter?.reason} </td>
                      <td>
                        {
                          responseLetter?.customValue === null ?
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
              <span className="corr-sectionlink">Edit Section</span>
            </Button>
          </div>
        </div>
        <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND })}>
          <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND, padding: '20px' })}>
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
              <span className="corr-sectionlink">Edit Section</span>
            </Button>
          </div>
        </div><div {...css({ backgroundColor: COLORS.GREY_BACKGROUND, padding: '20px' })}>
          <div {...css({
            borderBottom: '1px solid #d6d7d9',
            padding: '10px 0px',
            marginBottom: '20px',
            fontWeight: 'bold'
          })}>
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
              <span className="corr-sectionlink">Edit Section</span>
            </Button>
          </div>
        </div>
        <ConfirmTasksRelatedToAnAppeal />

        <div className="corr-flex">
          <h2 className="corr-h2">Tasks not related to an Appeal</h2>
          <div className="corr-autoleft">
            <Button className="corr-button" linkStyling onClick={() => props.goToStep(2)}>
              <span className="corr-icon"><PencilIcon /></span>
              <span className="corr-sectionlink">Edit Section</span>
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
  mailTasks: PropTypes.arrayOf(PropTypes.string)
};
export default ConfirmCorrespondenceView;
