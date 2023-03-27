/* eslint-disable camelcase */
import React from 'react';
import TextField from '../../components/TextField';
import { LABELS, DECISION_REASON_LABELS } from './cavcDashboardConstants';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../components/SearchableDropdown';
import { createFilter } from 'react-select';
import Button from '../../components/Button';

const MIN_INPUT_LENGTH = 3;

const basisForSelectionStylingNoChild = css({
  paddingLeft: '5rem',
  fontWeight: 'normal'
});

const basisForSelectionStylingNoChildReadOnly = css({
  paddingLeft: '6rem',
  fontWeight: 'normal'
});

const basisForSelectionStylingWithChild = css({
  paddingLeft: '7.5rem',
  fontWeight: 'normal',
});

const basisForSelectionStylingWithChildReadOnly = css({
  paddingLeft: '8.5rem',
  fontWeight: 'normal'
});

// Logic section for searchable dropdowns that prevents searching prior to 3 characters being entered
// noOptionMessage is currently being overwritten by the default value set in searchabledropdown.jsx
const filterOption = (candidate, input) => {
  if (input.length < MIN_INPUT_LENGTH) {
    return true;
  }

  return createFilter({})(candidate, input);
};

const CavcSelectionBasis = (props) => {
  const {
    type,
    parent,
    child,
    userCanEdit,
    basis,
    name,
    selectionBasesIndex,
    handleBasisChange,
    selectionBases,
    handleOtherTextFieldChange,
    handleRemoveBasis
  } = props;

  const renderBasisForSelectionsWithChild = () => {
    const defaultSelectionValue = basis?.label ? { label: basis.label, value: basis.value } : null;

    if (userCanEdit) {
      return (
        <>
          <div className="dash-basis-group">
            <SearchableDropdown
              name={name}
              filterOption={filterOption}
              label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
              placeholder="Type to search..."
              onChange={(option) => handleBasisChange(option, selectionBasesIndex, child, parent)}
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
              value={defaultSelectionValue?.label ? defaultSelectionValue : null}
            />
            <Button
              linkStyling
              onClick={() => handleRemoveBasis(basis, child, parent)}
            >
              <i className="fa fa-trash-o" aria-hidden="true"></i> {LABELS.REMOVE_BASIS_BUTTON_LABEL}
            </Button>
          </div>
          {defaultSelectionValue?.label === 'Other' && (
            <div className="dash-text-input" style={{ paddingLeft: '7.5rem' }}>
              <TextField
                type="string"
                label="New basis reason"
                onChange={(value) => handleOtherTextFieldChange(value, selectionBasesIndex, child, parent)}
                defaultValue={defaultSelectionValue?.otherText}
                inputProps={{ maxLength: 250 }}
              />
            </div>
          )}
        </>
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

  const renderBasisForSelectionsForParent = () => {
    const defaultSelectionValue = basis?.label ? { label: basis.label, value: basis.value } : null;

    if (userCanEdit) {
      return (
        <>
          <div className="dash-basis-group">
            <SearchableDropdown
              name={name}
              label={DECISION_REASON_LABELS.DECISION_REASON_BASIS_LABEL}
              filterOption={filterOption}
              options={selectionBases.
                filter((selection) => selection.category === parent.basis_for_selection_category).
                map((selection) => ({
                  label: selection.basis_for_selection,
                  value: selection.id,
                  checkboxId: parent.id
                }))}
              onChange={(option) => handleBasisChange(option, selectionBasesIndex, parent)}
              placeholder="Type to search..."
              styling={basisForSelectionStylingNoChild}
              readOnly={!userCanEdit}
              value={defaultSelectionValue?.label ? defaultSelectionValue : null}
            />
            <Button
              linkStyling
              onClick={() => handleRemoveBasis(basis, parent)}
            >
              <i className="fa fa-trash-o" aria-hidden="true"></i> {LABELS.REMOVE_BASIS_BUTTON_LABEL}
            </Button>
          </div>
          {defaultSelectionValue?.label === 'Other' && (
            <div className="dash-text-input" style={{ paddingLeft: '5rem' }}>
              <TextField
                type="string"
                label="New basis reason"
                onChange={(value) => handleOtherTextFieldChange(value, selectionBasesIndex, parent)}
                defaultValue={defaultSelectionValue?.otherText}
                inputProps={{ maxLength: 250 }}
              />
            </div>
          )}
        </>
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

  const basisToRender =
    type === 'parent' ? renderBasisForSelectionsForParent() :
      renderBasisForSelectionsWithChild();

  return basisToRender;
};

CavcSelectionBasis.propTypes = {
  type: PropTypes.string,
  parent: PropTypes.object,
  child: PropTypes.object,
  userCanEdit: PropTypes.bool,
  basis: PropTypes.object,
  name: PropTypes.string,
  selectionBasesIndex: PropTypes.number,
  handleBasisChange: PropTypes.func,
  selectionBases: PropTypes.arrayOf(PropTypes.object),
  handleOtherTextFieldChange: PropTypes.func,
  handleRemoveBasis: PropTypes.func
};

export default CavcSelectionBasis;
