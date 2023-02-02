
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import CAVC_REMAND_SUBTYPES from '../../../constants/CAVC_REMAND_SUBTYPES';
import Button from '../../components/Button';
import { PencilIcon } from '../../components/icons/PencilIcon';
import { DateString } from '../../util/DateUtil';

const CavcDashboardDetailsContainer = ({ children }) => {
  const containerStyling = css({
    display: 'flex',
    justifyContent: 'space-between',
    '@media(max-width: 829px)': {
      flexDirection: 'column'
    }
  });

  return <div {...containerStyling}>{children}</div>;
};

CavcDashboardDetailsContainer.propTypes = {
  children: PropTypes.node
};

export const CavcDashboardDetailsSection = ({ title, value }) => {
  const sectionStyling = css({
    padding: '0 0.5rem 0 0.5rem',
    '& > p': {
      fontWeight: 'bold',
      margin: '0'
    }
  });

  return (
    <div {...sectionStyling}>
      <p>{title}</p>
      <span>{value}</span>
    </div>
  );
};

CavcDashboardDetailsSection.propTypes = {
  title: PropTypes.string,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
};

export const CavcDashboardDetails = (props) => {
  const { remand } = props;

  // TODO: fix this date, remove eslint disable when the set methods are used for editing
  /* eslint-disable no-unused-vars */
  const [boardDecisionDate, setBoardDecisionDate] = useState(remand.source_appeal_decision_date);
  const [boardDocketNumber, setBoardDocketNumber] = useState(remand.source_appeal_docket_number);
  const [cavcDecisionDate, setCavcDecisionDate] = useState(remand.decision_date);
  const [cavcDocketNumber, setCavcDocketNumber] = useState(remand.cavc_docket_number);
  const [remandSubtype, setRemandSubtype] = useState(remand.remand_subtype);
  /* eslint-enable no-unused-vars */

  const checkIfJmrJmpr = () => {
    switch (remandSubtype) {
    case CAVC_REMAND_SUBTYPES.jmr:
    case CAVC_REMAND_SUBTYPES.jmpr:
    case CAVC_REMAND_SUBTYPES.jmr_jmpr:
      return true;
    default:
      return false;
    }
  };

  // modify this to return apporpriate boolean based on organization
  const userCanEdit = true;

  // top position bypasses the fixed margin on the TabWindow component
  const buttonStyling = css({
    position: 'relative',
    top: '-30px',
    margin: '0',
    // visibility used to maintain the spacing whether button is visible or not
    visibility: (userCanEdit ? 'visible' : 'hidden')
  });

  return (
    <div id={`dashboard-details-${remand.id}`}>
      <Button linkStyling willNeverBeLoading classNames={['cf-push-right', 'cf-modal-link']}
        styling={buttonStyling} disabled={!userCanEdit} onClick={null}
      >
        <span {...css({ position: 'absolute' })}><PencilIcon /></span>
        <span {...css({ marginLeft: '20px' })}>Edit</span>
      </Button>
      <CavcDashboardDetailsContainer>
        <CavcDashboardDetailsSection
          title={LABELS.BOARD_DECISION_DATE} value={<DateString date={boardDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.BOARD_DOCKET_NUMBER} value={boardDocketNumber} />
        <CavcDashboardDetailsSection
          title={LABELS.CAVC_DECISION_DATE} value={<DateString date={cavcDecisionDate} />}
        />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DOCKET_NUMBER} value={cavcDocketNumber} />
        <CavcDashboardDetailsSection title={LABELS.IS_JMR} value={checkIfJmrJmpr() ? 'Yes' : 'No'} />
      </CavcDashboardDetailsContainer>
    </div>
  );
};

CavcDashboardDetails.propTypes = {
  remandId: PropTypes.number,
  remand: PropTypes.object
};
