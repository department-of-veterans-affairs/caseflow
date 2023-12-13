import React from 'react';
import { useSelector } from 'react-redux';
import { COLORS } from 'app/constants/AppConstants';
import LinkToAppeal from '../../../../../hearings/components/assignHearings/LinkToAppeal';
import DocketTypeBadge from '../../../../../components/DocketTypeBadge';
import { ExternalLinkIcon } from '../../../../../components/icons/ExternalLinkIcon';
import PropTypes from 'prop-types';

const borderlessTd = {
  borderTop: 'none',
  borderBottom: 'none',
  backgroundColor: COLORS.GREY_BACKGROUND,
};

const ConfirmTasksRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const taskIds = useSelector((state) => state.intakeCorrespondence.taskRelatedAppealIds);
  const fetchedAppeals = useSelector((state) => state.intakeCorrespondence.fetchedAppeals);
  const waivedEvidenceTasks = useSelector((state) => state.intakeCorrespondence.waivedEvidenceTasks);

  const rowObjects = taskIds.map((task, index) => {
    const evidenceSubmission = (fetchedAppeals.find((appeal) => appeal.id === task).evidenceSubmissionTask);
    const waivedEvidenceTask = (waivedEvidenceTasks.find((waivedEvTask) => waivedEvTask.id === evidenceSubmission.id));

    const formatDocketName = () => {
      let unformattedText = fetchedAppeals.find((appeal) => appeal.id === task).docketName;

      unformattedText = unformattedText.replace('_', ' ');

      // Capitalize the first character of each string
      const formattedText = unformattedText.split(' ').map((text) =>
        text.charAt(0).toUpperCase() + text.slice(1)).
        join(' ').
        trim();

      return formattedText;
    };

    const getYesOrNo = () => {
      if (waivedEvidenceTask === null) {
        return waivedEvidenceTask.isWaived ? 'No' : 'Yes';
      }
    };

    return (
      <>
        <tr>
          <td style={{ ...borderlessTd, ...{ paddingBottom: '0px' } }}>
            <h3 style={{ lineHeight: '10%' }}>Appeal {index + 1} Tasks</h3>
          </td>
        </tr>
        <tr rowSpan="4">
          <td style={{ ...borderlessTd, ...{ paddingBottom: '10px' } }}>
            <b style={{ marginTop: '40px' }}>Linked Appeal</b>
          </td>
          <td style={borderlessTd}>
            <b>Currently Active Task</b>
          </td>
          <td style={borderlessTd}>
            <b>Evidence Window Waived?</b>
          </td>
          <td style={borderlessTd}>
            <b>Assigned To</b>
          </td>
        </tr>
        <tr>
          <td style={borderlessTd}>
            <div style={{ width: 'fit-content',
              padding: '3px',
              backgroundColor: 'white',
              border: `1px solid ${COLORS.COLOR_COOL_BLUE_LIGHTER}`,
              whiteSpace: 'nowrap'
            }}>
              <DocketTypeBadge name={(fetchedAppeals.find((appeal) => appeal.id === task).docketName)} />
              <LinkToAppeal appealExternalId={fetchedAppeals.find((appeal) => appeal.id === task).externalId}>
                <b>{fetchedAppeals.find((appeal) => appeal.id === task).docketNumber}</b>
                <ExternalLinkIcon size={15} className="cf-pdf-external-link-icon" color={COLORS.FOCUS_OUTLINE} />
              </LinkToAppeal>
            </div>
          </td>
          <td style={borderlessTd}>{formatDocketName()}</td>
          { <td style={borderlessTd}>{getYesOrNo()} {waivedEvidenceTask ?
           `Yes- ${waivedEvidenceTask.waiveReason}` : "No"}</td>  }
          <td style={borderlessTd}>{evidenceSubmission.assigned_to_type}</td>
        </tr>
        <tr>
          <td
            style={{ backgroundColor: COLORS.GREY_BACKGROUND,
              borderTop: 'none',
              borderSpacing: '0px' }}>
            <b>Additional Tasks</b>
          </td>
          <td
            colSpan="3"
            style={{ backgroundColor: COLORS.GREY_BACKGROUND,
              borderTop: 'none',
              borderSpacing: '0px' }}>
            <b>Task Instructions or Context</b>
          </td>
        </tr>
        {tasks.filter((taskById) => taskById.appealId === task).map((taskById) =>
          <tr>
            <td
              style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6', width: '20%' }}>
              {taskById.type}
            </td>
            <td colSpan={3} style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6' }}>
              {taskById.content}
            </td>
          </tr>)}

      </>
    );
  });

  return (
    <>
      <div style={{ marginLeft: 'auto' }}>
        <div
          style={{ background: COLORS.GREY_BACKGROUND, padding: '2rem', paddingTop: '0.5rem', marginBottom: '2rem' }}>
          <table className="usa-table-borderless">
            <tbody>
              {rowObjects}
            </tbody>
          </table>
        </div>
      </div></>
  );
};

ConfirmTasksRelatedToAnAppeal.propTypes = {
  bottonStyling: PropTypes.object,
  goToStepTwo: PropTypes.func.isRequired
};

export default ConfirmTasksRelatedToAnAppeal;
