/* eslint-disable max-lines */
/* eslint-disable camelcase */
import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import { LABELS, DECISION_REASON_LABELS } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons,
  setInitialCheckedDecisionReasons,
  setSelectionBasisForReasonCheckbox
} from './cavcDashboardActions';
import { CheckIcon } from '../../components/icons/fontAwesome/CheckIcon';
import CavcSelectionBasis from './CavcSelectionBasis';
import Button from '../../components/Button';

// left padding + margin should equal 5rem
const addBasisButtonForParentStyle = css({
  padding: '0 2rem',
  marginBottom: '2rem',
  marginLeft: '3rem'
});

// left padding + margin should equal 7.5rem
const addBasisButtonForChildStyle = css({
  padding: '0 2rem',
  marginBottom: '2rem',
  marginLeft: '5.5rem'
});

const CavcDecisionReasons = (props) => {
  const {
    uniqueId,
    initialDispositionRequiresReasons,
    dispositionIssueType,
    // loadCheckedBoxes => array cavc_dashboard_dispositions.cavc_dispositions_to_reasons in redux
    // { id (disposition_to_reason), dashboard disposition id, decision reason id, reasons to basis array}
    loadCheckedBoxes,
    userCanEdit
  } = props;

  const checkboxStyling = css({
    paddingLeft: '2.5rem',
    marginBlock: '0.75rem'
  });

  const childCheckboxStyling = css({
    paddingLeft: '5rem',
    marginBlock: '0.5rem'
  });

  const loadCheckedBoxesId = loadCheckedBoxes?.map((box) => box.cavc_decision_reason_id);
  const decisionReasons = useSelector((state) => state.cavcDashboard.decision_reasons);
  const checkedBoxesInStore = useSelector((state) => state.cavcDashboard.checked_boxes[uniqueId]);
  const initialCheckBoxesInStore = useSelector((state) => state.cavcDashboard.initial_state.checked_boxes[uniqueId]);
  const selectionBases = useSelector((state) => state.cavcDashboard.selection_bases);
  const parentReasons = decisionReasons.filter((parentReason) => !parentReason.parent_decision_reason_id).sort(
    (objA, objB) => objA.order - objB.order);
  const childReasons = decisionReasons.filter((childReason) => childReason.parent_decision_reason_id !== null).sort(
    (objA, objB) => objA.order - objB.order);
  const dispatch = useDispatch();

  const initialCheckboxes = parentReasons.reduce((obj, parent) => {

    // get all children where parent.id === child.parent_decision_reason_id
    // then create an object for each child, stored into parent's children property as array
    const children = childReasons.filter((child) => child.parent_decision_reason_id === parent.id);

    const parentDispositionsToReason = loadCheckedBoxes?.
      filter((box) => box.cavc_decision_reason_id === parent.id)[0];

    const parentReasonsToBases = parentDispositionsToReason?.cavc_reasons_to_bases;

    const formattedParentSelectionBases = parentReasonsToBases?.map((rtb) => {
      const selectionBasisLabel = selectionBases?.
        filter((basis) => basis.id === rtb.cavc_selection_basis_id)[0].basis_for_selection;

      return {
        checkboxId: parent.id,
        dispositions_to_reason_id: rtb.cavc_dispositions_to_reason_id,
        value: rtb.cavc_selection_basis_id ? rtb.cavc_selection_basis_id : null,
        label: selectionBasisLabel ? selectionBasisLabel : null,
        otherText: null
      };
    });

    obj[parent.id] = {
      ...parent,
      checked: loadCheckedBoxesId?.includes(parent.id),
      issueId: uniqueId,
      issueType: dispositionIssueType,
      selection_bases: parentReasonsToBases ? formattedParentSelectionBases : [],
      children: children.map((child) => {
        const childDispositionsToReasons = loadCheckedBoxes?.
          filter((box) => box.cavc_decision_reason_id === child.id)[0];

        const childReasonsToBases = childDispositionsToReasons?.cavc_reasons_to_bases;

        const formattedChildSelectionBases = childReasonsToBases?.map((rtb) => {
          const selectionBasisLabel = selectionBases?.
            filter((basis) => basis.id === rtb.cavc_selection_basis_id)[0].basis_for_selection;

          return {
            checkboxId: child.id,
            parentCheckboxId: parent.id,
            dispositions_to_reason_id: rtb.cavc_dispositions_to_reason_id,
            value: rtb.cavc_selection_basis_id ? rtb.cavc_selection_basis_id : null,
            label: selectionBasisLabel ? selectionBasisLabel : null,
            otherText: null
          };
        });

        return {
          ...child,
          issueType: dispositionIssueType,
          checked: loadCheckedBoxesId?.includes(child.id),
          selection_bases: childReasonsToBases ? formattedChildSelectionBases : []
        };
      })
    };

    return obj;
  }, {});

  // for tracking state of each checkbox
  const [checkedReasons, setCheckedReasons] = useState(checkedBoxesInStore || initialCheckboxes);

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
  const handleBasisChange = (option, selectionBasesIndex, box, parent) => {
    if (parent) {
      const childIndex = checkedReasons[parent.id].children.findIndex((child) => child.id === box.id);
      const newSelectionBases = new Array(...checkedReasons[parent.id]?.children[childIndex].selection_bases);

      newSelectionBases[selectionBasesIndex] = {
        checkboxId: box.id,
        parentCheckboxId: parent.id,
        dispositions_to_reason_id: checkedReasons[parent.id]?.children[childIndex].
          selection_bases[selectionBasesIndex].dispositions_to_reason_id,
        value: option.value,
        label: option.label,
        otherText: null
      };

      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parent.id],
          children: prevState[parent.id].children.map((child) => {
            if (child.id === box.id) {
              return {
                ...child,
                selection_bases: newSelectionBases
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
      const newSelectionBases = new Array(...checkedReasons[box.id].selection_bases);

      newSelectionBases[selectionBasesIndex] = {
        checkboxId: box.id,
        dispositions_to_reason_id:
          checkedReasons[box.id].selection_bases[selectionBasesIndex].dispositions_to_reason_id,
        value: option.value,
        label: option.label,
        otherText: null
      };

      setCheckedReasons((prevState) => ({
        ...prevState,
        [box.id]: {
          ...prevState[box.id],
          selection_bases: newSelectionBases
        }
      }));
    }

    dispatch(setSelectionBasisForReasonCheckbox(uniqueId, selectionBasesIndex, option));
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

  const handleOtherTextFieldChange = (value, selectionBasesIndex, reason, parentReason) => {
    if (parentReason) {
      const childIndex = checkedReasons[parentReason.id].children.findIndex((child) => child.id === reason.id);
      const newSelectionBases = new Array(...checkedReasons[parentReason.id].children[childIndex].selection_bases);

      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parentReason.id],
          children: prevState[parentReason.id].children.map((child) => {
            if (child.id === reason.id) {
              const childBasis = child.selection_bases[selectionBasesIndex];

              newSelectionBases[selectionBasesIndex] = {
                checkboxId: reason.id,
                parentCheckboxId: parentReason.id,
                dispositions_to_reason_id: childBasis.dispositions_to_reason_id,
                value: childBasis.value,
                label: childBasis.label,
                otherText: value
              };

              return {
                ...child,
                selection_bases: newSelectionBases
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
      const newSelectionBases = new Array(...checkedReasons[reason.id].selection_bases);

      setCheckedReasons((prevState) => {
        newSelectionBases[selectionBasesIndex] = {
          checkboxId: reason.id,
          dispositions_to_reason_id:
            prevState[reason.id].selection_bases[selectionBasesIndex].dispositions_to_reason_id,
          value: prevState[reason.id].selection_bases[selectionBasesIndex].value,
          label: prevState[reason.id].selection_bases[selectionBasesIndex].label,
          otherText: value
        };

        return {
          ...prevState,
          [reason.id]: {
            ...prevState[reason.id],
            selection_bases: newSelectionBases
          }
        };
      });
    }
  };

  const createArrayForAddBasis = (array) => {
    const newBasis = {
      checkboxId: null,
      dispositions_to_reason_id: null,
      value: null,
      label: null,
      otherText: null
    };
    const newBasesArray = new Array(...array);

    newBasesArray.push(newBasis);

    return newBasesArray;
  };

  const handleAddBasis = (target, parentOfChild) => {
    if (parentOfChild) {
      const childIndex = checkedReasons[parentOfChild.id].children.findIndex((child) => child.id === target.id);

      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parentOfChild.id],
          children: prevState[parentOfChild.id].children.map((child) => {
            if (child.id === target.id) {
              return {
                ...child,
                selection_bases:
                  createArrayForAddBasis(checkedReasons[parentOfChild.id].children[childIndex].selection_bases)
              };
            }

            return child;
          })
        };

        return {
          ...prevState,
          [parentOfChild.id]: updatedParent
        };
      });
    } else {
      setCheckedReasons((prevState) => ({
        ...prevState,
        [target.id]: {
          ...prevState[target.id],
          selection_bases: createArrayForAddBasis(checkedReasons[target.id].selection_bases)
        }
      }));
    }
  };

  const handleRemoveBasis = (basisToRemove, target, parentOfChild) => {
    if (parentOfChild) {
      const childIndex = checkedReasons[parentOfChild.id].children.findIndex((child) => child.id === target.id);
      const newBasesArray = new Array(...checkedReasons[parentOfChild.id].children[childIndex].selection_bases).
        filter((basis) => basis !== basisToRemove);

      setCheckedReasons((prevState) => {
        const updatedParent = {
          ...prevState[parentOfChild.id],
          children: prevState[parentOfChild.id].children.map((child) => {
            if (child.id === target.id) {
              return {
                ...child,
                selection_bases: newBasesArray
              };
            }

            return child;
          })
        };

        return {
          ...prevState,
          [parentOfChild.id]: updatedParent
        };
      });
    } else {
      const newBasesArray = new Array(...checkedReasons[target.id].selection_bases).
        filter((basis) => basis !== basisToRemove);

      setCheckedReasons((prevState) => ({
        ...prevState,
        [target.id]: {
          ...prevState[target.id],
          selection_bases: newBasesArray
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
                      childToFind.checked)?.selection_bases?.map((basis, idx) => {
                        return (
                          <CavcSelectionBasis
                            type="child"
                            parent={parent}
                            child={child}
                            userCanEdit={userCanEdit}
                            basis={basis}
                            issueId={uniqueId}
                            name={`decision-reason-basis-${uniqueId}-${child.id}-${idx}`}
                            selectionBasesIndex={idx}
                            handleBasisChange={handleBasisChange}
                            selectionBases={selectionBases}
                            handleOtherTextFieldChange={handleOtherTextFieldChange}
                            handleRemoveBasis={handleRemoveBasis}
                          />
                        );
                      })
                }
                {checkedReasons[parent.id]?.children?.find((childToFind) => childToFind.id === child.id &&
                  childToFind.basis_for_selection_category && childToFind.checked) && userCanEdit &&
                    <Button
                      name={`add-basis-${uniqueId}-${child.id}`}
                      linkStyling
                      styling={addBasisButtonForChildStyle}
                      onClick={() => handleAddBasis(child, parent)}
                    >
                      {LABELS.ADD_BASIS_BUTTON_LABEL}
                    </Button>}
              </div>
            ))}
            {/* check if parent checkbox has basis category but no child, if so render dropdown */}
            {checkedReasons[parent.id]?.basis_for_selection_category &&
              <>
                {(checkedReasons[parent.id].selection_bases?.map((basis, idx) => (
                  <CavcSelectionBasis
                    type="parent"
                    parent={parent}
                    userCanEdit={userCanEdit}
                    basis={basis}
                    issueId={uniqueId}
                    name={`decision-reason-basis-${uniqueId}-${parent.id}-${idx}`}
                    selectionBasesIndex={idx}
                    handleBasisChange={handleBasisChange}
                    selectionBases={selectionBases}
                    handleOtherTextFieldChange={handleOtherTextFieldChange}
                    handleRemoveBasis={handleRemoveBasis}
                  />
                )))}
                {userCanEdit &&
                  <Button
                    name={`add-basis-${uniqueId}-${parent.id}`}
                    linkStyling
                    styling={addBasisButtonForParentStyle}
                    onClick={() => handleAddBasis(parent)}
                  >
                    {LABELS.ADD_BASIS_BUTTON_LABEL}
                  </Button>
                }
              </>
            }
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
