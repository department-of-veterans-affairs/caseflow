import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { LABELS } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons } from './cavcDashboardActions';

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
  const dispatch = useDispatch();

  // get all children where parent.id === child.parent_decision_reason_id
  // then create an object for each child, stored into parent's children property as array

  const [checkedReasons, setCheckedReasons] = useState(parentReasons.reduce((obj, parent) => {
    const children = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    obj[parent.id] = {
      ...parent,
      checked: false,
      children: children.map((child) => {

        return {
          ...child,
          checked: false,
        };
      })
    };

    return obj;
  }, {}));

  // update state of checkboxes everytime checkbox is updated
  useEffect(() => {
    dispatch(setCheckedDecisionReasons(checkedReasons, uniqueId));
  }, [checkedReasons]);

  const handleCheckboxChange = (value, checkboxId) => {
    // if checkboxId < parentReasons.length then it is a parent checkbox therefore update parent checked value
    if (checkboxId <= parentReasons.length) {
      setCheckedReasons((prevState) => ({
        ...prevState,
        [checkboxId]: {
          ...prevState[checkboxId],
          checked: value
        }
      }));
    } else {
      // if checkboxId > parentReasons.length then it is a child checkbox therefore update child checkbox
      // must obtain parent id to update correct child property
      const parent = parentReasons.find(
        (parentToFind) => parentToFind.id === childReasons.find(
          (child) => child.id === checkboxId).parent_decision_reason_id);

      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parent.id],
          children: prevState[parent.id].children.map((child) => {
            if (child.id === checkboxId) {
              return {
                ...child,
                checked: value
              };
            }

            return child;
          })
        };

        return {
          ...prevState,
          [parent.id]: updatedParent
        };
      });
    }
  };
  // const checkedParentReasonsCount = checkedReasons.filter((reason) =>
  //   reason.id <= parentReasons.length && reason.checked).length;

  const reasons = parentReasons.map((parent) => {
    const childrenOfParent = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    return (
      <div key={parent.id}>
        <Checkbox
          name={`checkbox-${parent.id}-${uniqueId}`}
          label={parent.decision_reason}
          onChange={(value) => handleCheckboxChange(value, parent.id)}
          value={checkedReasons[parent.id]?.checked}
          styling={checkboxStyling}
        />
        {checkedReasons[parent.id]?.checked && (
          <div>
            {childrenOfParent.map((child) => (
              <Checkbox
                key={child.id}
                name={`checkbox-${child.id}-${uniqueId}`}
                label={child.decision_reason}
                onChange={(value) => handleCheckboxChange(value, child.id)}
                value={checkedReasons[child.id]?.checked}
                styling={childCheckboxStyling}
              />
            ))}
          </div>
        )}
      </div>
    )
  });
  // ${checkedParentReasonsCount ? `(${checkedParentReasonsCount})` : ''}

  return (
    <>
      <Accordion
        style="bordered"
        id={`accordion-${uniqueId}`}
        header={`${LABELS.CAVC_DECISION_REASONS}`}
      >
        <AccordionSection id={`accordion-${uniqueId}`} >
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
