/* eslint-disable max-lines */
/* eslint-disable camelcase */
import React, { useEffect, useState } from 'react';
import { Accordion } from '../../components/Accordion';
import Checkbox from '../../components/Checkbox';
import AccordionSection from 'app/components/AccordionSection';
import TextField from '../../components/TextField';
import { DECISION_REASON_LABELS } from './cavcDashboardConstants';
import { useDispatch, useSelector } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import { setCheckedDecisionReasons,
  setInitialCheckedDecisionReasons,
  setSelectionBasisForReasonCheckbox,
  updateOtherFieldTextValue } from './cavcDashboardActions';
import SearchableDropdown from '../../components/SearchableDropdown';
import { createFilter } from 'react-select';
import { CheckIcon } from '../../components/icons/fontAwesome/CheckIcon';

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
    paddingLeft: '8rem',
    fontWeight: 'normal',
    '@media(min-width: 1200px)': { paddingLeft: '14rem' },
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

    obj[parent.id] = {
      ...parent,
      checked: loadCheckedBoxesId?.includes(parent.id),
      issueId: uniqueId,
      issueType: dispositionIssueType,
      basis_for_selection: {
        checkboxId: parent.id,
        value: parentSelectionBasisId,
        label: selectionBases?.filter((basis) => basis.id === parentSelectionBasisId)[0]?.basis_for_selection,
        otherText: null
      },
      children: children.map((child) => {
        const childSelectionBasisId = loadCheckedBoxes?.
          filter((box) => box.cavc_decision_reason_id === child.id)[0]?.cavc_selection_basis_id;

        return {
          ...child,
          issueType: dispositionIssueType,
          checked: loadCheckedBoxesId?.includes(child.id),
          basis_for_selection: {
            checkboxId: child.id,
            parentCheckboxId: parent.id,
            value: childSelectionBasisId,
            label: selectionBases?.filter((basis) => basis.id === childSelectionBasisId)[0]?.basis_for_selection,
            otherText: null
          }
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

  // Logic section for searchable dropdowns that prevents searching prior to 3 characters being entered
  // noOptionMessage is currently being overwritten by the default value set in searchabledropdown.jsx
  const MIN_INPUT_LENGTH = 3;
  const noOptionsMessage = (input) =>
    input.length >= MIN_INPUT_LENGTH ?
      'No options' :
      'Search input must be at least 3 characters';
  const filterOption = (candidate, input) => {
    return (
      // Min input length
      input.length >= MIN_INPUT_LENGTH &&
      // Use Select's default filtering for string matching by creating filter
      createFilter({})(candidate, input)
    );
  };

  const [otherBasisSelectedByCheckboxId, setOtherBasisSelectedByCheckboxId] = useState(decisionReasons.map((reason) => {
    return { checkboxId: reason.id, checked: false };
  }));

  const handleOtherTextFieldChange = (value, reason, parentReason) => {
    const reasons = {
      checkboxId: reason.id,
      parentCheckboxId: parentReason?.id
    };

    dispatch(updateOtherFieldTextValue(uniqueId, value, reasons));
  };

  const renderBasisForSelectionsWithChild = (parent, child) => {
    const defaultSelectionValue =
      checkedReasons[parent.id]?.children.filter((box) => child.id === box.id)[0]?.basis_for_selection;

    if (userCanEdit) {
      return (
        <div>
          <SearchableDropdown
            name={`decision-reason-basis-${child.id}`}
            filterOption={filterOption}
            label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
            placeholder="Type to search..."
            noOptionsMessage={noOptionsMessage}
            onChange={(option) => {
              if (option.label === 'Other') {
                setOtherBasisSelectedByCheckboxId((prevState) => {
                  const idx = otherBasisSelectedByCheckboxId.findIndex((basis) => basis.checkboxId === child.id);
                  const arr = [...prevState];

                  arr[idx] = { checkboxId: child.id, checked: true };

                  return arr;
                });
              } else {
                setOtherBasisSelectedByCheckboxId((prevState) => {
                  const idx = otherBasisSelectedByCheckboxId.findIndex((basis) => basis.checkboxId === child.id);
                  const arr = [...prevState];

                  arr[idx] = { checkboxId: child.id, checked: false };

                  return arr;
                });
              }
              dispatch(setSelectionBasisForReasonCheckbox(uniqueId, option));
            }
            }
            options={selectionBases.
              filter((selection) => selection.category === child.basis_for_selection_category).
              map((selection) => ({
                label: selection.basis_for_selection,
                value: selection.id,
                category: selection.category,
                checkboxId: child.id,
                parentCheckboxId: parent.id
              }))}
            styling={basisForSelectionStylingWithChild}
            defaultValue={defaultSelectionValue?.label ? defaultSelectionValue : null}
          />
          {(otherBasisSelectedByCheckboxId.filter((basis) => basis.checkboxId === child.id)[0].checked) && (
            <div style={{ paddingLeft: '10rem', paddingTop: '2.5rem' }}>
              <TextField
                type="string"
                label="New basis reason"
                onChange={(value) => handleOtherTextFieldChange(value, child, parent)}
                defaultValue={defaultSelectionValue?.otherText}
                inputProps={{ maxLength: 250 }}
              />
            </div>
          )}
        </div>
      );
    }

    return (
      <div {...basisForSelectionStylingWithChildReadOnly}>
        <label>
          <strong>{DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}:</strong>{' '}
          {defaultSelectionValue?.label}
        </label>
      </div>
    );
  };

  const renderBasisForSelectionsForParent = (parent) => {
    const defaultSelectionValue = checkedReasons[parent.id]?.basis_for_selection;

    if (userCanEdit) {
      return (
        <div>
          <SearchableDropdown
            name={`decision-reason-basis-${parent.id}`}
            label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
            filterOption={filterOption}
            options={selectionBases.
              filter((selection) => selection.category === parent.basis_for_selection_category).
              map((selection) => ({
                label: selection.basis_for_selection,
                value: selection.id,
                checkboxId: parent.id
              }))}
            onChange={(option) => {
              if (option.label === 'Other') {
                setOtherBasisSelectedByCheckboxId((prevState) => {
                  const idx = otherBasisSelectedByCheckboxId.findIndex((basis) => basis.checkboxId === parent.id);
                  const arr = [...prevState];

                  arr[idx] = { checkboxId: parent.id, checked: true };

                  return arr;
                });
              } else {
                setOtherBasisSelectedByCheckboxId((prevState) => {
                  const idx = otherBasisSelectedByCheckboxId.findIndex((basis) => basis.checkboxId === parent.id);
                  const arr = [...prevState];

                  arr[idx] = { checkboxId: parent.id, checked: false };

                  return arr;
                });
              }
              dispatch(setSelectionBasisForReasonCheckbox(uniqueId, option));
            }
            }
            placeholder="Type to search..."
            noOptionsMessage={noOptionsMessage}
            styling={basisForSelectionStylingNoChild}
            readOnly={!userCanEdit}
            defaultValue={defaultSelectionValue?.label ? defaultSelectionValue : null}
          />
          {(otherBasisSelectedByCheckboxId.filter((basis) => basis.checkboxId === parent.id)[0].checked) && (
            <div style={{ paddingLeft: '7.5rem', paddingTop: '2.5rem' }}>
              <TextField
                type="string"
                label="New basis reason"
                onChange={(value) => handleOtherTextFieldChange(value, parent)}
                defaultValue={defaultSelectionValue?.otherText}
                inputProps={{ maxLength: 250 }}
              />
            </div>
          )}
        </div>
      );
    }

    return (
      <div {...basisForSelectionStylingNoChildReadOnly}>
        <label>
          <strong>{DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}:</strong>{' '}
          {defaultSelectionValue?.label}
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
