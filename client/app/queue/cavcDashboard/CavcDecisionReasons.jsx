import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { DECISION_REASON_TEXT, DECISION_REASON_TITLE } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons } from './cavcDashboardActions';
import SearchableDropdown from '../../components/SearchableDropdown';

const CavcDecisionReasons = ({ uniqueId }) => {

  const checkboxStyling = css({
    paddingLeft: '2.5%',
    marginBlock: '0.75rem'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5%',
    marginBlock: '0.5rem'
  });

  const basisForSelectionStylingNoChild = css({
    paddingLeft: '5%',
    fontWeight: 'normal'
  });

  const basisForSelectionStylingWithChild = css({
    paddingLeft: '7.5%',
    fontWeight: 'normal'
  });

  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);
  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null);
  const dispatch = useDispatch();

  // for tracking state of each checkbox
  const [checkedReasons, setCheckedReasons] = useState(parentReasons.reduce((obj, parent) => {

    // get all children where parent.id === child.parent_decision_reason_id
    // then create an object for each child, stored into parent's children property as array
    const children = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    obj[parent.id] = {
      ...parent,
      checked: false,
      issueId: uniqueId,
      children: children.map((child) => {

        return {
          ...child,
          checked: false,
        };
      })
    };

    return obj;
  }, {}));

  // counter for parent checkboxes that are checked to display next to the header
  const decisionReasonCount = Object.keys(checkedReasons).filter((key) => checkedReasons[key].checked).length;

  useEffect(() => {
    dispatch(setCheckedDecisionReasons(checkedReasons, uniqueId));
  }, [checkedReasons]);

  // toggling state of checkbox when checkbox is clicked
  const handleCheckboxChange = (value, checkboxId) => {
    // if checkboxId < parentReasons.length then it is a parent checkbox therefore update parent checked state
    if (checkboxId <= parentReasons.length) {
      setCheckedReasons((prevState) => ({
        ...prevState,
        [checkboxId]: {
          ...prevState[checkboxId],
          checked: value
        }
      }));
    } else {
      // if checkboxId > parentReasons.length then it is a child checkbox therefore update child checked state
      // obtain parent id to update correct child property
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

            // keep child object the same if checkboxId does not match to child.id
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

  const reasons = parentReasons.map((parent) => {
    const childrenOfParent = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    return (
      <div>
        {/* render parent checkboxes */}
        <Checkbox
          key={parent.id}
          name={`checkbox-${parent.id}-${uniqueId}`}
          label={parent.decision_reason}
          onChange={(value) => handleCheckboxChange(value, parent.id)}
          value={checkedReasons[parent.id]?.checked}
          styling={checkboxStyling}
        />
        {/* render child checkbox if parent is checked */}
        {checkedReasons[parent.id]?.checked && (
          <div>
            {childrenOfParent.map((child) => (
              <div>
                <Checkbox
                  key={child.id}
                  name={`checkbox-${child.id}-${uniqueId}`}
                  label={child.decision_reason}
                  onChange={(value) => handleCheckboxChange(value, child.id)}
                  value={checkedReasons[parent.id].children.find((x) => x.id === child.id).checked}
                  styling={childCheckboxStyling}
                />
                {/* check if child checkbox is checked and basis category exists if so render component */}
                {checkedReasons[parent.id]?.children.find(
                  (x) => x.id === child.id && x.basis_for_selection_category)?.checked && (
                    <SearchableDropdown
                      name={`decision-reason-basis-${child.id}`}
                      label="Basis for this selection"
                      placeholder="Type to search..."
                      styling={basisForSelectionStylingWithChild}
                    />
                  )}
              </div>
            ))}
            {/* check if parent checkbox has basis category but no child, if so render component  */}
            {/* eslint-disable-next-line */}
            {checkedReasons[parent.id]?.basis_for_selection_category && (
              <SearchableDropdown
                name={`decision-reason-basis-${parent.id}`}
                label="Basis for this selection"
                placeholder="Type to search..."
                styling={basisForSelectionStylingNoChild}
              />
            )}
          </div>
        )}
      </div>
    );
  });

  return (
    <>
      <Accordion
        style="bordered"
        id={`accordion-${uniqueId}`}
        header={`${DECISION_REASON_TITLE}${decisionReasonCount > 0 ? `(${decisionReasonCount})` : ''}`}
      >
        <AccordionSection id={`accordion-${uniqueId}`} >
          <p style={{ fontWeight: 'normal' }}>{DECISION_REASON_TEXT}</p>
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
