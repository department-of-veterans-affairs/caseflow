import * as React from 'react';
import PropTypes from 'prop-types';

import { taskActionData } from '../utils';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop, setHeight } from '../constants';
import TextareaField from 'app/components/TextareaField';
import SearchableDropdown from '../../components/SearchableDropdown';
import COPY from '../../../COPY';

export const VhaReturnToBoardIntakeModal = ({ props, state, setState }) => {
  const taskConfiguration = taskActionData(props);
  const dropdownOptions = taskConfiguration.options;

  const handleDropdownChange = ({ value }) => {
    setState({ dropdown: value });
    if (value === 'other') {
      setState({ otherInstructions: '' });
    }
  };

  const validInstructions = (instructions) => {
    return instructions?.length > 0;
  };

  const validDropdown = (dropdown) => {
    return dropdown?.length > 0;
  };

  return <>
    <div style={{ marginBottom: '1.5em' }}>{props.modalBody || COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_BODY}</div>
    {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
      <div>
        <SearchableDropdown
          name="returnToBoardOptions"
          id="returnToBoardOptions"
          label={props.dropdownLabel || COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_DETAIL}
          defaultText={props.dropdownDefaultText || COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
          onChange={handleDropdownChange}
          value={state.dropdown}
          options={dropdownOptions}
          errorMessage={props.highlightInvalid &&
            !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
        />
        {state.dropdown === 'other' &&
          <TextareaField
            label={props.otherLabel || COPY.VHA_RETURN_TO_BOARD_INTAKE_OTHER_INSTRUCTIONS_LABEL}
            name="otherRejectReason"
            id="completeTaskOtherInstructions"
            onChange={(value) => setState({ otherInstructions: value })}
            value={state.otherInstructions}
            styling={marginTop(2)}
            textAreaStyling={setHeight(4.5)}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
          />}
        <TextareaField
          label={props.instructionsLabel || COPY.VHA_RETURN_TO_BOARD_INTAKE_OTHER_INSTRUCTIONS_LABEL}
          name="instructions"
          id="vhaReturnToBoardIntakeInstructions"
          onChange={(value) => setState({ instructions: value })}
          value={state.instructions}
          styling={marginTop(4)}
          maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
          errorMessage={props.highlightInvalid &&
            !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
          optional
        />
      </div>
    )}
  </>;
};

VhaReturnToBoardIntakeModal.propTypes = {
  props: PropTypes.object,
  tasks: PropTypes.array,
  setState: PropTypes.func,
  state: PropTypes.object,
  highlightInvalid: PropTypes.bool,
  taskConfiguration: PropTypes.object,
  instructionsOptional: PropTypes.bool,
  modalBody: PropTypes.string,
  dropdownLabel: PropTypes.string,
  dropdownDefaultText: PropTypes.string,
  instructionsLabel: PropTypes.string,
  otherLabel: PropTypes.string
};

export default VhaReturnToBoardIntakeModal;
