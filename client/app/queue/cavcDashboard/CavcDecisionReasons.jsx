import React, { useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { LABELS } from './cavcDashboardConstants';
import { useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const CavcDecisionReasons = ({ uniqueId }) => {

  const checkboxStyling = css({
    paddingLeft: '2.5%',
    marginBlock: 'auto'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5%',
    marginBlock: 'auto'
  });

  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);
  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null);

  // get all children where parent.id === child.parent_decision_reason_id
  // then create an object for each child, stored into array
  const [checkedReasons, setCheckedReasons] = useState(parentReasons.map((reason) => {
    const children = childReasons.filter(
      (child) => child.parent_decision_reason_id === reason.id).map(
      (childReason) => {

        return {
          id: childReason.id,
          decisionReason: childReason.decision_reason,
          checked: false,
          issueId: uniqueId
        };
      });

    return {
      id: reason.id,
      decisionReason: reason.decision_reason,
      checked: false,
      children,
      issueId: uniqueId
    };
  }));
  const handleCheckboxChange = (value, checkboxId, issueId) => {
    setCheckedReasons(checkedReasons.map((reason) => {
      if (reason.id === checkboxId) {
        return {
          ...reason,
          checked: value,
          issueId
        };
      } else if (checkboxId >= checkedReasons.length) {
        return {
          ...reason,
          children: reason.children.map((child) => {
            if (child?.id === checkboxId) {
              return {
                ...child,
                checked: value,
                issueId
              };
            }
          })
        };
      }

      return reason;
    }));
  };

  const reasons = parentReasons.map((parent) => {
    const childrenOfParent = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    return (
      <div key={parent.id}>
        <Checkbox
          name={`checkbox-${parent.id}-${uniqueId}`}
          label={parent.decision_reason}
          onChange={(value) => handleCheckboxChange(value, parent.id, uniqueId)}
          value={checkedReasons.find((reason) => reason.id === parent.id)?.checked}
          styling={checkboxStyling}
        />
        {checkedReasons[parent.id - 1].checked && (
          <div>
            {childrenOfParent.map((child) => (
              <Checkbox
                key={child.id}
                name={`checkbox-${child.id}-${uniqueId}`}
                label={child.decision_reason}
                onChange={(value) => handleCheckboxChange(value, child.id, uniqueId)}
                value={checkedReasons.find((reason) => reason.id === child.id)?.checked}
                styling={childCheckboxStyling}
              />
            ))}
          </div>
        )}
      </div>
    )
  });

  return (
    <>
      <Accordion style="bordered" accordion id={`accordion-${uniqueId}`}>
        <AccordionSection title={`${LABELS.CAVC_DECISION_REASONS}`} id={`accordion-${uniqueId}`} >
          <p style={{ fontWeight: 'normal' }}>Select reasons why this issue's decision was changed</p>
          {reasons}
        </AccordionSection>
      </Accordion>
    </>
  );
};

CavcDecisionReasons.propTypes = {
  uniqueId: PropTypes.number,
};

export default CavcDecisionReasons;

