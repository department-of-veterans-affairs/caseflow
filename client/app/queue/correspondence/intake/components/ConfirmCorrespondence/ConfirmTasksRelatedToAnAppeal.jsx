import React from 'react';
import { useSelector } from 'react-redux';
import { COLORS } from 'app/constants/AppConstants';
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
  const taskIds = useSelector((state) => state.intakeCorrespondence.taskRelatedAppealIds).
    sort((first, second) => first - second);
  const fetchedAppeals = useSelector((state) => state.intakeCorrespondence.fetchedAppeals);
  const waivedEvidenceTasks = useSelector((state) => state.intakeCorrespondence.waivedEvidenceTasks);

  const rowObjects = taskIds.map((task, index) => {
    const evidenceSubmission = (fetchedAppeals.find((appeal) => appeal.id === task).evidenceSubmissionTask);
    const waivedEvidenceTask = (waivedEvidenceTasks.find((waivedEvTask) => waivedEvTask.id === evidenceSubmission.id));

    const formatDocketName = () => {
      const currentAppeal = fetchedAppeals.find((appeal) => appeal.id === task);

      if (currentAppeal && evidenceSubmission) {
        let unformattedText = currentAppeal.docketName;

        unformattedText = unformattedText.replace('_', ' ');

        // Capitalize the first character of each string
        const formattedText = unformattedText.split(' ').map((text) =>
          text.charAt(0).toUpperCase() + text.slice(1)).
          join(' ').
          trim();

        return formattedText;
      }

      return '';
    };

    // Handles what to display for EvidenceW Window Waived? column
    const getYesOrNo = () => {
      if (waivedEvidenceTask) {
        return `Yes - ${waivedEvidenceTask.waiveReason}`;
      }

      if (evidenceSubmission) {
        return 'No';
      }

      return '';
    };

    // Gives less space to the first appeal, and more to all after.
    const paddingAmount = index === 0 ? 'first-style-for-appeals-number-tasks' : 'style-for-appeals-number-tasks';

    return (
      <>
        <tr>
          <td className={paddingAmount} >
            <h3 className="style-for-appeals-number-title">Appeal {index + 1} Tasks</h3>
          </td>
        </tr>
        <tr rowSpan="4">
          <td className="style-for-appeals-first-row">
            <b className="style-for-appeals-first-row-title">Linked Appeal</b>
          </td>
          <td className="style-for-appeals-second-row">
            <b>{evidenceSubmission && 'Currently Active Task'}</b>
          </td>
          <td className="style-for-appeals-third-row">
            <b>{evidenceSubmission && 'Evidence Window Waived?'}</b>
          </td>
          <td className="style-for-appeals-fourth-row">
            <b>{evidenceSubmission && 'Assigned To'}</b>
          </td>
        </tr>
        <tr>
          <td style={borderlessTd}>
            <div className="linked-appeal-link-button">
              <a
                href={`/queue/appeals/${fetchedAppeals.find((appeal) => appeal.id === task).externalId}`}
                target="_blank"
                rel="noopener noreferrer">
                <DocketTypeBadge name={(fetchedAppeals.find((appeal) => appeal.id === task).docketName)} />
                <b>{fetchedAppeals.find((appeal) => appeal.id === task).docketNumber}</b>
                <ExternalLinkIcon size={15} className="cf-pdf-external-link-icon" color={COLORS.FOCUS_OUTLINE} />
              </a>
            </div>
          </td>
          <td className="currently-active-task-answer">{formatDocketName()}</td>
          <td className="evidence-window-waived-answer">{getYesOrNo()}</td>
          <td className="assigned-to-answer">{evidenceSubmission ? evidenceSubmission.assigned_to_type : ''}</td>
        </tr>
        <tr>
          <td className="additional-tasks-row">
            <b>Additional Tasks</b>
          </td>
          <td className="tasks-instructions-or-context" colSpan="3">
            <b>Task Instructions or Context</b>
          </td>
        </tr>
        {tasks.filter((taskById) => taskById.appealId === task).map((taskById) =>
          <tr>
            <td className="additional-tasks-row-content">
              {taskById.label}
            </td>
            <td className="tasks-instructions-or-context" colSpan={3}>
              {taskById.content}
            </td>
          </tr>)}

      </>
    );
  });

  const renderingTask = () => {

    if (taskIds.length === 0) {
      const taskRenderer = <div
        className="correspondence-not-related-to-appeal"> Correspondence is not related to an existing appeal</div>;

      return taskRenderer;
    }
    const taskRenderer = <table className="usa-table-borderless">
      <tbody>
        {rowObjects}
      </tbody>
    </table>;

    return taskRenderer;

  };

  return (
    <>
      <div className="linked-appeals-and-new-tasks-margin">
        <div className="linked-appeal-and-new-tasks-box">
          {renderingTask()}
        </div>
      </div></>
  );
};

ConfirmTasksRelatedToAnAppeal.propTypes = {
  bottonStyling: PropTypes.object
};

export default ConfirmTasksRelatedToAnAppeal;
