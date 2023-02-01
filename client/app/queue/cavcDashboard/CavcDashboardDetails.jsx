import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { LABELS } from './cavcDashboardConstants';
import CAVC_REMAND_SUBTYPES from '../../../constants/CAVC_REMAND_SUBTYPES';
import Button from '../../components/Button';
import { PencilIcon } from '../../components/icons/PencilIcon';

const CavcDashboardDetailsContainer = ({ children }) => {
  const containerStyling = css({
    display: 'flex',
    justifyContent: 'space-between'
  });

  return (
    <div {...containerStyling}>
      {children}
    </div>
  );
};

CavcDashboardDetailsContainer.propTypes = {
  children: PropTypes.node
};

export const CavcDashboardDetailsSection = ({ title, value }) => {
  return (
    <div>
      <h4>{title}</h4>
      <span>{value}</span>
    </div>
  );
};

CavcDashboardDetailsSection.propTypes = {
  title: PropTypes.string,
  value: PropTypes.string,
};

export const CavcDashboardDetails = (props) => {
  const { remand } = props;

  const checkIfJmrJmpr = () => {
    switch (remand.remand_subtype) {
    case CAVC_REMAND_SUBTYPES.jmr:
    case CAVC_REMAND_SUBTYPES.jmpr:
    case CAVC_REMAND_SUBTYPES.jmr_jmpr:
      return true;
    default:
      return false;
    }
  };

  return (
    <>
      {/* change true to a check for user's orgs to display edit button */}
      {true && (
        <div {...css({ display: 'inline-block', width: '100%' })}>
          <Button linkStyling willNeverBeLoading onClick={null} classNames={['cf-push-right', 'cf-modal-link']}>
            <span {...css({ position: 'absolute' })}><PencilIcon /></span>
            <span {...css({ marginRight: '5px', marginLeft: '20px' })}>Edit</span>
          </Button>
        </div>
      )}
      <CavcDashboardDetailsContainer>
        <CavcDashboardDetailsSection title={LABELS.BOARD_DECISION_DATE} value={remand.decision_date} />
        <CavcDashboardDetailsSection title={LABELS.BOARD_DOCKET_NUMBER} value={remand.source_appeal_docket_number} />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DECISION_DATE} value={remand.decision_date} />
        <CavcDashboardDetailsSection title={LABELS.CAVC_DOCKET_NUMBER} value={remand.cavc_docket_number} />
        <CavcDashboardDetailsSection title={LABELS.IS_JMR} value={checkIfJmrJmpr() ? 'Yes' : 'No'} />
      </CavcDashboardDetailsContainer>
    </>
  );
};

CavcDashboardDetails.propTypes = {
  remandId: PropTypes.number,
  remand: PropTypes.object
};
