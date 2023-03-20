/* eslint-disable camelcase */
import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { DECISION_REASON_LABELS } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons,
  setInitialCheckedDecisionReasons,
  setSelectionBasisForReasonCheckbox
} from './cavcDashboardActions';
import { CheckIcon } from '../../components/icons/fontAwesome/CheckIcon';
import CavcSelectionBasis from './CavcSelectionBasis';

const CavcDecisionReasons = (props) => {
  const {
    uniqueId,
    initialDispositionRequiresReasons,
    dispositionIssueType,
    loadCheckedBoxes,
    userCanEdit
  } = props;

  const checkboxStyling = css({
    paddingLeft: '2.5%',
    marginBlock: '0.75rem'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5%',
    marginBlock: '0.5rem'
  });

  const loadCheckedBoxesId = loadCheckedBoxes?.map((box) => box.cavc_decision_reason_id);
  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);
  const checkedBoxesInStore = useSelector((state) => state.cavcDashboard.checked_boxes[uniqueId]);
  const initialCheckBoxesInStore = useSelector((state) => state.cavcDashboard.initial_state.checked_boxes[uniqueId]);
  const selectionBases = useSelector((state) => state.cavcDashboard.selection_bases);
  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id).sort(
    (obj) => obj.order);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null).sort(
    (obj) => obj.order);
  const dispatch = useDispatch();

  const initialCheckboxes = parentReasons.reduce((obj, parent) => {

    // get all children where parent.id === child.parent_decision_reason_id
    // then create an object for each child, stored into parent's children property as array
    const children = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);
    const parentSelectionBasisId = loadCheckedBoxes?.
      filter((box) => box.cavc_decision_reason_id === parent.id)[0]?.cavc_selection_basis_id;

    const parentSelectionBasisLabel = selectionBases?.
      filter((basis) => basis.id === parentSelectionBasisId)[0]?.basis_for_selection;

    obj[parent.id] = {
      ...parent,
      checked: loadCheckedBoxesId?.includes(parent.id),
      issueId: uniqueId,
      issueType: dispositionIssueType,
      basis_for_selection: {
        checkboxId: parent.id,
        value: parentSelectionBasisId ? parentSelectionBasisId : null,
        label: parentSelectionBasisLabel ? parentSelectionBasisLabel : null,
        otherText: null
      },
      children: children.map((child) => {
        const childSelectionBasisId = loadCheckedBoxes?.
          filter((box) => box.cavc_decision_reason_id === child.id)[0]?.cavc_selection_basis_id;
        const childSelectionBasisLabel = selectionBases?.
          filter((basis) => basis.id === childSelectionBasisId)[0]?.basis_for_selection;

        return {
          ...child,
          issueType: dispositionIssueType,
          checked: loadCheckedBoxesId?.includes(child.id),
          basis_for_selection: {
            checkboxId: child.id,
            parentCheckboxId: parent.id,
            value: childSelectionBasisId ? childSelectionBasisId : null,
            label: childSelectionBasisLabel ? childSelectionBasisLabel : null,
            otherText: null
          }
        };
      })
    };

    return obj;
  }, {});

  // for tracking state of each checkbox
  const [checkedReasons, setCheckedReasons] = useState(checkedBoxesInStore || initialCheckboxes);
  const [otherBasisSelectedByCheckboxId, setOtherBasisSelectedByCheckboxId] = useState(decisionReasons.map((reason) => {
    return { checkboxId: reason.id, checked: false };
  }));

  useEffect(() => {
    dispatch(setCheckedDecisionReasons(checkedReasons, uniqueId));
    if (!initialCheckBoxesInStore && initialDispositionRequiresReasons) {
      dispatch(setInitialCheckedDecisionReasons(uniqueId));
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

  // the parent checkboxes do not provide a "parent" arg, only the child boxes
  const handleBasisChange = (option, box, parent) => {
    if (parent) {
      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parent.id],
          children: prevState[parent.id].children.map((child) => {
            if (child.id === box.id) {
              return {
                ...child,
                basis_for_selection: {
                  checkboxId: box.id,
                  parentCheckboxId: parent.id,
                  value: option.value,
                  label: option.label,
                  otherText: null
                }
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
    } else {
      setCheckedReasons((prevState) => ({
        ...prevState,
        [box.id]: {
          ...prevState[box.id],
          basis_for_selection: {
            checkboxId: box.id,
            value: option.value,
            label: option.label,
            otherText: null
          }
        }
      }));
    }

    setOtherBasisSelectedByCheckboxId((prevState) => {
      const idx = otherBasisSelectedByCheckboxId.findIndex((basis) => basis.checkboxId === box.id);
      const arr = [...prevState];

      arr[idx] = { checkboxId: box.id, checked: (option.label === 'Other') };

      return arr;
    });
    dispatch(setSelectionBasisForReasonCheckbox(uniqueId, option));
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
          name={`${uniqueId}-${parent.id}-${parent.decision_reason}`}
          label={parent.decision_reason}
          onChange={(value) => handleCheckboxChange(value, parent.id)}
          value={checkedReasons[parent.id]?.checked}
          styling={checkboxStyling}
          ariaLabel={parent.decision_reason}
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
          name={`${uniqueId}-${child.id}-${child.decision_reason}`}
          label={child.decision_reason}
          onChange={(value) => handleCheckboxChange(value, child.id)}
          value={checkedReasons[parent.id]?.children?.find((x) => x.id === child.id).checked}
          styling={childCheckboxStyling}
          disabled={!userCanEdit}
          ariaLabel={child.decision_reason}
        />
      );
    }

    return readOnlyDecisionReason(
      child.decision_reason,
      childCheckboxStyling,
      checkedReasons[parent.id]?.children?.find((x) => x.id === child.id).checked
    );
  };

  const handleOtherTextFieldChange = (value, reason, parentReason) => {
    if (parentReason) {
      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parentReason.id],
          children: prevState[parentReason.id].children.map((child) => {
            if (child.id === reason.id) {
              const childBasis = child.basis_for_selection;

              return {
                ...child,
                basis_for_selection: {
                  checkboxId: reason.id,
                  parentCheckboxId: parentReason.id,
                  value: childBasis.value,
                  label: childBasis.label,
                  otherText: value
                }
              };
            }

            return child;
          })
        };

        return {
          ...prevState,
          [parentReason.id]: updatedParent
        };
      });
    } else {
      setCheckedReasons((prevState) => ({
        ...prevState,
        [reason.id]: {
          ...prevState[reason.id],
          basis_for_selection: {
            checkboxId: reason.id,
            value: prevState[reason.id].basis_for_selection.value,
            label: prevState[reason.id].basis_for_selection.label,
            otherText: value
          }
        }
      }));
    }
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
                      <CavcSelectionBasis
                        type="child"
                        parent={parent}
                        child={child}
                        userCanEdit
                        checkedReasons={checkedReasons}
                        handleBasisChange={handleBasisChange}
                        selectionBases={selectionBases}
                        otherBasisSelectedByCheckboxId={otherBasisSelectedByCheckboxId}
                        handleOtherTextFieldChange={handleOtherTextFieldChange}
                      />
                }
              </div>
            ))}
            {/* check if parent checkbox has basis category but no child, if so render dropdown */}
            {checkedReasons[parent.id]?.basis_for_selection_category &&
              <CavcSelectionBasis
                type="parent"
                parent={parent}
                userCanEdit
                checkedReasons={checkedReasons}
                handleBasisChange={handleBasisChange}
                selectionBases={selectionBases}
                otherBasisSelectedByCheckboxId={otherBasisSelectedByCheckboxId}
                handleOtherTextFieldChange={handleOtherTextFieldChange}
              />}
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
  initialDispositionRequiresReasons: PropTypes.bool,
  dispositionIssueType: PropTypes.string,
  fetchCavcSelectionBases: PropTypes.func,
  loadCheckedBoxes: PropTypes.arrayOf(PropTypes.shape({
    cavc_dashboard_disposition_id: PropTypes.number,
    cavc_decision_reason_id: PropTypes.number,
    cavc_selection_basis_id: PropTypes.number,
    id: PropTypes.number
  })),
  userCanEdit: PropTypes.bool
};

export default CavcDecisionReasons;
