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
    borderColor: '#d6d7d9',
    paddingTop: '0vh',
    paddingBottom: '0vh',
  },
});

const tableStyling = css({
  marginBottom: '-2vh',
  marginTop: '2vh'
});
const bottonStyling = css({
  paddingRight: '10px'
});

export const ConfirmCorrespondenceView = (props) => {

  const checkedMailTasks = Object.keys(props.mailTasks).filter((name) => props.mailTasks[name]);
  const relatedCorrespondences = useSelector((state) => state.intakeCorrespondence.relatedCorrespondences);

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

  return (
    <div className="gray-border corr">
      <h1 className="corr-h1">Review and Confirm Correspondence</h1>
      <p className="corr-p">
        Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <CorrespondenceDetailsTable />
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
        <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND})}>
          <div {...css({ backgroundColor: COLORS.GREY_BACKGROUND, padding: '20px' })}>
            <Table
              columns={getDocumentColumns}
              // columnsToDisplay={15}
              rowObjects={relatedCorrespondences}
              styling="corr-table"
              bodyStyling="corr-tablebody" />
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
          {checkedMailTasks.map((name, index, array) => (
            <div
              key={index}
              {...css({
                borderBottom: index === array.length - 1 ? 'none' : '1px solid #d6d7d9',
                padding: '10px 10px',
                marginBottom: '10px',
              })}
            >
              {props.mailTasks[name] && <span>{name}</span>}
            </div>
          ))}
        </div>
      </div>
      <div>
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

      </div>
    </div>
  );
};

ConfirmCorrespondenceView.propTypes = {
  goToStep: PropTypes.func,
  mailTasks: PropTypes.objectOf(PropTypes.bool)
};
export default ConfirmCorrespondenceView;
