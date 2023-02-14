import React, { useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { LABELS } from './cavcDashboardConstants';
import { useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const CavcDecisionReasons = ({ index }) => {

  const checkboxStyling = css({
    paddingLeft: '2.5%',
    marginBlock: 'auto'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5%',
    marginBlock: 'auto'
  });

  const [checkedParentReasons, setCheckedParentReasons] = useState([]);
  const [checkedChildReasons, setCheckedChildReasons] = useState([]);
  // const [parentCheckedCount, setParentCheckedCount] = useState();
  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);

  const handleParentCheckboxChange = (value, id) => {
    setCheckedParentReasons({
      ...checkedParentReasons,
      [id]: value
    });
    // setParentCheckedCount(checkedParentReasons.length);
  };

  const handleChildCheckboxChange = (value, id) => {
    setCheckedChildReasons({
      ...checkedChildReasons,
      [id]: value
    });
  };

  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null);

  const reasons = parentReasons.map((parent) => {
    return (
      <div>
        <Checkbox
          key={parent.id}
          name={`checkbox-${parent.id}`}
          label={parent.decision_reason}
          onChange={(value) => handleParentCheckboxChange(value, parent.id)}
          value={checkedParentReasons[parent.id]}
          styling={checkboxStyling}
        />
        {childReasons.filter((childReason) =>
          childReason.parent_decision_reason_id === parent.id).map((child) => {
          if (checkedParentReasons[child.parent_decision_reason_id]) {
            return (
              <Checkbox
                key={child.id}
                name={`checkbox-${child.id}`}
                label={child.decision_reason}
                onChange={(value) => handleChildCheckboxChange(value, child.id)}
                value={checkedChildReasons[child.id]}
                styling={childCheckboxStyling}
              />
            );
          }
        })}
      </div>
    );
  });

  return (
    <>
      <Accordion style="bordered" id={index}>
        <AccordionSection title={`${LABELS.CAVC_DECISION_REASONS}`} id={index}>
          <p style={{ fontWeight: 'normal' }}>Select reasons why this issue's decision was changed</p>
          {reasons}
        </AccordionSection>
      </Accordion>
    </>
  )
};

CavcDecisionReasons.propTypes = {
  index: PropTypes.number,
}

export default CavcDecisionReasons;

