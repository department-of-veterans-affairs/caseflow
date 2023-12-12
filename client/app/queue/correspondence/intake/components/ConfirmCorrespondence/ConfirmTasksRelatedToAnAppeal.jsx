import React from 'react';
import { useSelector } from 'react-redux';
import { COLORS } from 'app/constants/AppConstants';
import LinkToAppeal from '../../../../../hearings/components/assignHearings/LinkToAppeal';
import DocketTypeBadge from '../../../../../components/DocketTypeBadge';
import { ExternalLinkIcon } from '../../../../../components/icons/ExternalLinkIcon';
import PropTypes from 'prop-types';
import { marginBottom, marginTop } from '../../../../constants';

const styling = { backgroundColor: COLORS.GREY_BACKGROUND, border: 'none' };

const borderlessTd = {
  borderTop: 'none',
  borderBottom: 'none',
  backgroundColor: COLORS.GREY_BACKGROUND,
};



const ConfirmTasksRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks);
  const taskIds = useSelector((state) => state.intakeCorrespondence.taskRelatedAppealIds);
  const fetchedAppeals = useSelector((state) => state.intakeCorrespondence.fetchedAppeals);
  const rowObjects = taskIds.map((task, index) => {
    return (
      <>
        <tr>
          <td colSpan={1} style={{...borderlessTd, ...{paddingBottom:'0px'}}}>
            <h3 style={{lineHeight:'10%'}}>Appeal {index + 1} Tasks</h3>
          </td>
        </tr>
        <tr rowSpan='4'>
          <td colSpan='1' style={{ ...borderlessTd, ...{ paddingBottom: '10px' } }}>
            <b style={{ marginTop: '40px' }}>Linked appeal</b>
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
        <tr colSpan='100%'>
          <td style={borderlessTd}>
            <div style={{ width: 'fit-content',
              padding: '3px',
              backgroundColor: 'white',
              border: `1px solid ${COLORS.COLOR_COOL_BLUE_LIGHTER}`,
            }}>
              <DocketTypeBadge name={(fetchedAppeals.find((appeal) => appeal.id === task).docketName)} />
              <LinkToAppeal appealExternalId={fetchedAppeals.find((appeal) => appeal.id === task).externalId}>
                <b>{fetchedAppeals.find((appeal) => appeal.id === task).docketNumber}</b>
                <ExternalLinkIcon size={15} className="cf-pdf-external-link-icon" color={COLORS.FOCUS_OUTLINE} />
              </LinkToAppeal>
            </div>
          </td>
          <td style={borderlessTd}>hi</td>
          <td style={borderlessTd}>hi</td>
          <td style={borderlessTd}>hi</td>
        </tr>
        <tr colSpan="100%">
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
