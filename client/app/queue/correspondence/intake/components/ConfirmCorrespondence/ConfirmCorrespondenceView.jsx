import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { PencilIcon } from '../../../../../components/icons/PencilIcon';
import Button from '../../../../../components/Button';
import { useSelector } from 'react-redux';
import CorrespondenceDetailsTable from './CorrespondenceDetailsTable';
import ConfirmTasksNotRelatedToAnAppeal from './ConfirmTasksNotRelatedToAnAppeal';
import Table from '../../../../../components/Table';

const bodyStyling = css({
  '& > tr > td': {
    backgroundColor: '#f5f5f5',
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
  paddingRight: '0px'
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
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review and Confirm Correspondence</h1>
      <p style={{ fontSize: '.85em' }}>
        Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <br></br>
      <div>
        <CorrespondenceDetailsTable />
      </div>
      <div>
        <div style={{ display: 'flex' }}>
          <h2 style={{ margin: '1px 0 15px 0',
            display: 'inline-block' }}>
                Associated Prior Mail
          </h2>
          <div style={{ marginLeft: 'auto' }}>
            <Button styling={bottonStyling} linkStyling onClick={() => props.goToStep(1)}>
              <div style={{ marginLeft: 'auto' }}>
                <span {...css({ position: 'absolute' })}><PencilIcon /></span>
                <span {...css({ marginLeft: '20px' })}>Edit Section</span>
              </div>
            </Button>
          </div>
        </div>

        <div {...css({ backgroundColor: '#f5f5f5', marginBottom: '20px' })}>

          <div {...css({ backgroundColor: '#f5f5f5', padding: '20px' })}>
            <Table
              columns={getDocumentColumns}
              // columnsToDisplay={15}
              rowObjects={relatedCorrespondences}
              bodyStyling= {bodyStyling}
              styling={tableStyling}
            />

          </div>
        </div>
        <div style={{ display: 'flex' }}>
          <h2 style={{
            margin: '1px 0 15px 0',
            display: 'inline-block',
            marginLeft: '0px'
          }}>Completed Mail Tasks</h2>
          <div style={{ marginLeft: 'auto' }}>
            <Button styling={bottonStyling} linkStyling onClick={() => props.goToStep(2)}>
              <span {...css({ position: 'absolute' })}><PencilIcon /></span>
              <span {...css({ marginLeft: '20px' })}>Edit Section</span>
            </Button>
          </div>
        </div>
        <div {...css({ backgroundColor: '#f5f5f5', padding: '20px', marginBottom: '20px' })}>
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
        <div style={{ display: 'flex' }}>
          <h2 style={{
            margin: '1px 0 15px 0',
            display: 'inline-block',
            marginLeft: '0px'
          }}>Tasks not related to an Appeal</h2>
          <div style={{ marginLeft: 'auto' }}>
            <Button styling={bottonStyling} linkStyling onClick={() => props.goToStep(2)}>
              <span {...css({ position: 'absolute' })}><PencilIcon /></span>
              <span {...css({ marginLeft: '20px' })}>Edit Section</span>
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
  mailTasks: PropTypes.objectOf(PropTypes.bool)
};
export default ConfirmCorrespondenceView;
