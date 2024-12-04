import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { COLORS as extraColors, LOGO_COLORS } from '../../../constants/AppConstants';
import Button from '../../../components/Button';
import { Link } from 'react-router-dom/cjs/react-router-dom.min';
import { css } from 'glamor';
import LoadingContainer from '../../../components/LoadingContainer';

const ConfirmWorkOrderModal = ({ history, onCancel }) => {
  const { state } = history.location;

  const [transcriptionFiles, setTranscriptionFiles] = useState([]);
  const [isLoading, setIsloading] = useState(true);

  const styles = {
    body: {
      border: 'solid 2px',
      borderColor: COLORS.GREY_LIGHT,
      margin: '3rem'
    },
    buttonSection: {
      display: 'flex',
      justifyContent: 'space-between',
      marginRight: '3rem',
      paddingTop: '3rem'
    },
    formInfoSection: {
      listStyleType: 'none',
      marginTop: '-3rem',
    },
    tableSection: {
      display: 'inline-block',
      borderTop: '1px solid',
      marginTop: '3rem',
      width: '95%',
      marginLeft: '3rem',
      borderBottom: '1px solid',
      borderColor: COLORS.GREY_LIGHT,
      padding: '2rem 0'
    },
    table: {
      width: '100%',
      marginTop: '-2rem'
    },
    advanceOnDocket: {
      color: extraColors.RED
    },
    numberOfFiles: {
      marginLeft: '0rem'
    },
    docketNumber: {
      fontWeight: 'bold'
    },
    summaryHeader: {
      fontWeight: 'bold'
    }
  };

  const marginStyles = css({
    '& h1': {
      margin: '3rem'
    },
    '& button': {
      margin: '2rem'
    },
    '& a': {
      margin: '3rem'
    },
    '& h4': {
      margin: '3rem',
      fontSize: '17px'
    },
    '& h2': {
      margin: '3rem',
    },
    '& p': {
      marginTop: '2.9rem',
      marginLeft: '1rem'
    },
    '& li': {
      display: 'inline-flex',
      marginLeft: '2rem',
      marginBottom: '-4rem'
    },
    '& ul': {
      display: 'inline-grid',
      marginLeft: '-3rem'
    },
    '& th': {
      borderRight: 'none',
      borderLeft: 'none',
      borderTop: 'none',
      fontWeight: 'bold',
      borderColor: COLORS.GREY_LIGHT
    },
    '& td': {
      borderRight: 'none',
      borderLeft: 'none',
      borderTop: 'none',
      borderColor: COLORS.GREY_LIGHT
    },
    '& .loadingContainer-content': {
      height: '25rem'
    }
  });

  const renderFormInformation = () => {
    return (
      <ul style={styles.formInfoSection}>
        <li><p style={styles.summaryHeader}>Work Order:</p><p>{state?.workOrder}</p></li>
        <li><p style={styles.summaryHeader}>Return date:</p><p>{state?.returnDateValue}</p></li>
        <li><p style={styles.summaryHeader}>Contractor:</p><p>{state?.contractor?.name}</p></li>
      </ul>
    );
  };

  const renderFiles = (files) => {
    return files.map((file, index) =>
      <>
        <tr>
          <td>{index + 1}.</td>
          <td style={styles.docketNumber}>{file.docketNumber}</td>
          <td>{file.firstName}</td>
          <td>{file.lastName}</td>
          <td>{file.isAdvancedOnDocket && <><span style={styles.advanceOnDocket}>AOD</span>,</>} {file.caseType}</td>
          <td>{file.hearingDate}</td>
          <td>{file.regionalOffice}</td>
          <td>{file.judge}</td>
          <td>{file.appealType}</td>
        </tr>
      </>
    );
  };

  const renderTranscriptionFilesTable = () => {
    return (
      <table style={styles.table} >
        <tr>
          <th></th>
          <th>{COPY.TABLE_DOCKET_NUMBER}</th>
          <th>{COPY.TRANSCRIPTION_TABLE_FIRST_NAME}</th>
          <th>{COPY.TRANSCRIPTION_TABLE_LAST_NAME}</th>
          <th>{COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE}</th>
          <th>{COPY.TRANSCRIPTION_FILE_DISPATCH_HEARING_DATE_COLUMN_NAME}</th>
          <th>{COPY.TRANSCRIPTION_TABLE_RO}</th>
          <th>{COPY.TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL}</th>
          <th>{COPY.TRANSCRIPTION_TABLE_APPEAL_TYPE}</th>
        </tr>
        {renderFiles(transcriptionFiles)}
      </table>
    );
  };

  const getSelectedFilesInfo = (files) => {
    const ids = files.map((file) => file.id);

    ApiUtil.get(`/hearings/transcription_files/selected_files_info/${ids}`).
      then((response) => {
        setTranscriptionFiles(response.body);
        setIsloading(false);
      });
  };

  const renderLoading = () => <LoadingContainer color={LOGO_COLORS.HEARINGS.ACCENT} />;

  const renderTableSection = () => {
    return (
      <div style={styles.tableSection}>
        <h2 style={styles.numberOfFiles}>Number of files: {state?.selectedFiles?.length}</h2>
        {(isLoading && renderLoading()) || renderTranscriptionFilesTable()}
      </div>
    );
  };

  const cancelWorkOrder = (files) => {
    const ids = files.map((file) => file.id);
    const data = {
      file_ids: ids,
      status: false
    };

    ApiUtil.post('/hearings/transcription_files/lock', { data }).then(onCancel());
  };

  const dispatchWorkOrder = () => {
    const hearings = transcriptionFiles.map((file) => {
      return {
        hearing_id: file.hearingId,
        hearing_type: file.appealType === 'AMA' ? 'Hearing' : 'LegacyHearing'
      };
    });

    const payload = {
      work_order_name: state.workOrder,
      sent_to_transcriber_date: new Date().toISOString(),
      return_date: state.returnDateValue,
      contractor_name: state.contractor.name,
      hearings,
    };

    ApiUtil.post('/hearings/transcription_packages/dispatch',
      {
        data: payload
      }).then(() => onCancel());
  };

  const renderButtonSection = () => {
    return (
      <div style={styles.buttonSection}>
        <Link onClick={() => cancelWorkOrder(state?.selectedFiles)}>Cancel</Link>
        <div>
          <Button
            classNames={['usa-button', 'usa-button-secondary']}
            onClick={onCancel}
          >
            {COPY.TRANSCRIPTION_TABLE_MODIFY_WORK_ORDER}
          </Button>
          <Button onClick={dispatchWorkOrder}>{COPY.TRANSCRIPTION_TABLE_DISPATCH_WORK_ORDER}</Button>
        </div>
      </div>
    );
  };

  useEffect(() => {
    getSelectedFilesInfo(state?.selectedFiles);
  }, []);

  return (
    <div {...marginStyles} style={styles.body}>
      <h1>Confirm work order summary</h1>
      {renderFormInformation()}
      {renderTableSection()}
      {renderButtonSection()}
    </div>
  );
};

ConfirmWorkOrderModal.propTypes = {
  history: PropTypes.object,
  onCancel: PropTypes.func,
};

export default ConfirmWorkOrderModal;
