import * as React from 'react';
import PropTypes from 'prop-types';
import { ATTORNEY_COMMENTS_MAX_LENGTH, marginTop, setHeight } from '../constants';
import TextareaField from 'app/components/TextareaField';
import SearchableDropdown from '../../components/SearchableDropdown';
import COPY from '../../../COPY';

export const VhaReturnToBoardIntakeModal = (props) => {
  const taskConfiguration = props.taskConfiguration;
  const dropdownOptions = taskConfiguration.options;

  const { state, setState } = props;

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

  return (
    <React.Fragment>
      <div style= {{ marginBottom: '1.5em' }}>{props.modalBody}</div>
      {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
        <div>
          <SearchableDropdown
            name="returnToBoardOptions"
            id="returnToBoardOptions"
            label={props.dropdownLabel}
            defaultText={props.dropdownDefaultText}
            onChange={handleDropdownChange}
            value={state.dropdown}
            options={dropdownOptions}
            errorMessage={props.highlightInvalid &&
              !validDropdown(state.dropdown) ? COPY.VHA_RETURN_TO_BOARD_INTAKE_RETURN_REASON_DETAIL : null}
          />
          {state.dropdown === 'other' &&
            <TextareaField
              label={props.otherLabel}
              name="otherRejectReason"
              id="completeTaskOtherInstructions"
              onChange={(value) => setState({ otherInstructions: value })}
              value={state.otherInstructions}
              styling={marginTop(2)}
              textAreaStyling={setHeight(4.5)}
              errorMessage={props.highlightInvalid &&
                !validInstructions(state.otherInstructions) ?
                  COPY.VHA_RETURN_TO_BOARD_INTAKE_RETURN_REASON_TEXTAREA_DETAIL :
                  null
              }
            />}
          <TextareaField
            label={props.instructionsLabel}
            name="instructions"
            id="vhaReturnToBoardIntakeInstructions"
            onChange={(value) => setState({ instructions: value })}
            value={state.instructions}
            styling={marginTop(4)}
            maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
            errorMessage={props.highlightInvalid &&
              !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
            optional={props.instructionsOptional}
          />
        </div>
      )}
    </React.Fragment>
  );
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
