import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import TextField from '../../components/TextField';
import { DECISION_REASON_LABELS } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons, setInitialCheckedDecisionReasons } from './cavcDashboardActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import { CheckIcon } from '../../components/icons/fontAwesome/CheckIcon';

const CavcDecisionReasons = ({ uniqueId, dispositionIssueType, loadCheckedBoxes, userCanEdit }) => {

  const checkboxStyling = css({
    paddingLeft: '2.5%',
    marginBlock: '0.75rem'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5%',
    marginBlock: '0.5rem'
  });

  const basisForSelectionStylingNoChild = css({
    paddingLeft: '7.5rem',
    fontWeight: 'normal'
  });

  const basisForSelectionStylingNoChildReadOnly = css({
    paddingLeft: '6.5rem',
    fontWeight: 'normal',
    '@media(min-width: 1200px)': { paddingLeft: '8.5rem' },
  });

  const basisForSelectionStylingWithChild = css({
    paddingLeft: '10rem',
    fontWeight: 'normal',
  });

  const basisForSelectionStylingWithChildReadOnly = css({
    paddingLeft: '9rem',
    fontWeight: 'normal',
    '@media(min-width: 1200px)': { paddingLeft: '14rem' },
  });

  const loadCheckedBoxesId = loadCheckedBoxes?.map((box) => box.cavc_decision_reason_id);
  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);
  const checkedBoxesInStore = useSelector((state) => state.cavcDashboard.checked_boxes[uniqueId]);
  const initialCheckBoxesInStore = useSelector((state) => state.cavcDashboard.initial_state.checked_boxes);

  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id).sort(
    (obj) => obj.order);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null).sort(
    (obj) => obj.order);
  const dispatch = useDispatch();

  const initialCheckboxes = parentReasons.reduce((obj, parent) => {

    // get all children where parent.id === child.parent_decision_reason_id
    // then create an object for each child, stored into parent's children property as array
    const children = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    obj[parent.id] = {
      ...parent,
      checked: loadCheckedBoxesId?.includes(parent.id),
      issueId: uniqueId,
      issueType: dispositionIssueType,
      children: children.map((child) => {

        return {
          ...child,
          issueType: dispositionIssueType,
          checked: loadCheckedBoxesId?.includes(child.id),
        };
      })
    };

    return obj;
  }, {});

  // for tracking state of each checkbox
  const [checkedReasons, setCheckedReasons] = useState(checkedBoxesInStore || initialCheckboxes);

  useEffect(() => {
    dispatch(setCheckedDecisionReasons(checkedReasons, uniqueId));
    if (!initialCheckBoxesInStore) {
      dispatch(setInitialCheckedDecisionReasons());
    }
  }, [checkedReasons]);

  // counter for parent checkboxes that are checked to display next to the header
  const decisionReasonCount = Object.keys(checkedReasons).filter((key) => checkedReasons[key].checked).length;

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
      // set all children of parent to false if parent is unchecked
      if (value === false) {
        setCheckedReasons((prevState) => ({
          ...prevState,
          [checkboxId]: {
            ...prevState[checkboxId],
            children: prevState[checkboxId].children.map((child) => {
              return {
                ...child,
                checked: false
              };
            })
          }
        }));
      }
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

            // while iterating, keep child object the same if checkboxId does not match to child.id
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

  const readOnlyDecisionReason = (label, styling, checked) => {
    const uncheckedStyle = css(
      {
        marginLeft: '2rem'
      }
    );

    if (checked) {
      return (
        <div {...styling}>
          <label><CheckIcon /> {label}</label>
        </div>
      );
    }

    return (
      <div {...styling} {...uncheckedStyle} >
        <label> {label}</label>
      </div>
    );
  };

  const renderParentDecisionReason = (parent) => {
    if (userCanEdit) {
      return (
        <Checkbox
          key={parent.id}
          name={parent.decision_reason}
          label={parent.decision_reason}
          onChange={(value) => handleCheckboxChange(value, parent.id)}
          value={checkedReasons[parent.id]?.checked}
          styling={checkboxStyling}
        />
      );
    }

    return readOnlyDecisionReason(parent.decision_reason, checkboxStyling, checkedReasons[parent.id]?.checked);
  };

  const renderChildDecisionReason = (parent, child) => {
    if (userCanEdit) {
      return (
        <Checkbox
          key={child.id}
          name={child.decision_reason}
          label={child.decision_reason}
          onChange={(value) => handleCheckboxChange(value, child.id)}
          value={checkedReasons[parent.id]?.children?.find((x) => x.id === child.id).checked}
          styling={childCheckboxStyling}
          disabled={!userCanEdit}
        />
      );
    }

    return readOnlyDecisionReason(
      child.decision_reason,
      childCheckboxStyling,
      checkedReasons[parent.id]?.children?.find((x) => x.id === child.id).checked
    );
  };

  const renderBasisForSelectionsWithChild = (parent, child) => {
    if (userCanEdit) {
      return (
        <div>
          <SearchableDropdown
            name={`decision-reason-basis-${child.id}`}
            label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
            placeholder="Type to search..."
            styling={basisForSelectionStylingWithChild}
          />
          {/* if basis for selection category is ama_other display text field for custom reasoning */}
          {/* eslint-disable-next-line */}
          {checkedReasons[parent.id]?.children.find((x) => x.basis_for_selection_category === 'ama_other') && (
            <div style={{ paddingLeft: '10rem', paddingTop: '2.5rem' }}>
              <TextField type="string" label="New basis reason" />
            </div>
          )}
        </div>
      );
    }

    return (
      <div {...basisForSelectionStylingWithChildReadOnly}>
        <label>
          <strong>{DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}:</strong>{' '}
          Should be replaced with actual selection or no value
        </label>
      </div>
    );
  };

  const renderBasisForSelectionsForParent = (parent) => {
    if (userCanEdit) {
      return (
        <SearchableDropdown
          name={`decision-reason-basis-${parent.id}`}
          label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
          placeholder="Type to search..."
          styling={basisForSelectionStylingNoChild}
          readOnly={!userCanEdit}
        />
      );
    }

    return (
      <div {...basisForSelectionStylingNoChildReadOnly}>
        <label>
          <strong>{DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}:</strong>{' '}
          Should be replaced with actual selection or no value
        </label>
      </div>
    );
  };

  const reasons = parentReasons.map((parent) => {
    const childrenOfParent = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    return (
      <div key={parent.id}>
        {/* render parent checkboxes */}
        {renderParentDecisionReason(parent)}
        {/* render child checkbox if parent is checked */}
        {checkedReasons[parent.id]?.checked && (
          <div>
            {childrenOfParent.map((child) => (
              <div>
                {renderChildDecisionReason(parent, child)}
                {/* check if child checkbox is checked and basis category exists if so render dropdown */}
                {checkedReasons[parent.id]?.children?.find(
                  (childToFind) => childToFind.id === child.id &&
                    childToFind.basis_for_selection_category &&
                      childToFind.checked) &&
                      renderBasisForSelectionsWithChild(parent, child)
                }
              </div>
            ))}
            {/* check if parent checkbox has basis category but no child, if so render dropdown */}
            {/* eslint-disable-next-line */}
            {checkedReasons[parent.id]?.basis_for_selection_category && renderBasisForSelectionsForParent(parent)}
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
        header={`${DECISION_REASON_LABELS.DECISION_REASON_TITLE}
          ${decisionReasonCount > 0 ? ` (${decisionReasonCount})` : ''}`
        }
      >
        <AccordionSection id={`accordion-${uniqueId}`} >
          <p style={{ fontWeight: 'normal' }}>{DECISION_REASON_LABELS.DECISION_REASON_PROMPT}</p>
          {reasons}
        </AccordionSection>
      </Accordion>
    </>
  );
};

CavcDecisionReasons.propTypes = {
  uniqueId: PropTypes.number,
  dispositionIssueType: PropTypes.string,
  loadCheckedBoxes: PropTypes.shape({
    cavc_dashboard_disposition_id: PropTypes.number,
    cavc_decision_reason_id: PropTypes.number,
    cavc_selection_basis_id: PropTypes.number,
    id: PropTypes.number
  }),
  userCanEdit: PropTypes.bool
};

export default CavcDecisionReasons;
