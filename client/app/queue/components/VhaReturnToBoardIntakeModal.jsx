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
              !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
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
                !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
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
  register: PropTypes.func,
  featureToggles: PropTypes.array,
  highlightInvalid: PropTypes.bool,
  taskConfiguration: PropTypes.object,
  instructionsOptional: PropTypes.bool
};

// const VhaCamoReturnToBoardIntakeModal = ({ props, state, setState }) => {
//     const taskConfiguration = taskActionData(props);
//     const dropdownOptions = taskConfiguration.options;
  
//     const handleDropdownChange = ({ value }) => {
//       handleDropdownStateChange(value, setState);
//     };
  
//     return (
//       <React.Fragment>
//         {taskConfiguration && taskConfiguration.modal_body}
//         <div style= {{ marginBottom: '1.5em' }}>{COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_BODY}</div>
//         {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
//           <div>
//             <SearchableDropdown
//               name="returnToBoardOptions"
//               id="returnToBoardOptions"
//               label={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_DETAIL}
//               defaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
//               onChange={handleDropdownChange}
//               value={state.dropdown}
//               options={dropdownOptions}
//               errorMessage={props.highlightInvalid &&
//                 !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
//             />
//             {state.dropdown === 'other' &&
//               <TextareaField
//                 label={COPY.VHA_RETURN_TO_BOARD_INTAKE_OTHER_INSTRUCTIONS_LABEL}
//                 name="otherRejectReason"
//                 id="completeTaskOtherInstructions"
//                 onChange={(value) => setState({ otherInstructions: value })}
//                 value={state.otherInstructions}
//                 styling={marginTop(2)}
//                 textAreaStyling={setHeight(4.5)}
//                 errorMessage={props.highlightInvalid &&
//                   !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
//               />}
//             <TextareaField
//               label={COPY.VHA_RETURN_TO_BOARD_INTAKE_MODAL_INSTRUCTIONS_LABEL}
//               name="instructions"
//               id="vhaReturnToBoardIntakeInstructions"
//               onChange={(value) => setState({ instructions: value })}
//               value={state.instructions}
//               styling={marginTop(4)}
//               maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
//               errorMessage={props.highlightInvalid &&
//                 !validInstructions(state.instructions) ? COPY.EMPTY_INSTRUCTIONS_ERROR : null}
//             />
//           </div>
//         )}
//       </React.Fragment>
//     );
//   };



//   const VhaCaregiverSupportReturnToBoardIntakeModal = ({ props, state, setState }) => {
//     const taskConfiguration = taskActionData(props);
  
//     const dropdownOptions = taskConfiguration.options;
  
//     const handleDropdownChange = ({ value }) => {
//       handleDropdownStateChange(value, setState);
//     };
  
//     return (
//       <React.Fragment>
//         {taskConfiguration && taskConfiguration.modal_body}
//         {(!taskConfiguration || !taskConfiguration.modal_hide_instructions) && (
//           <div style= {{ marginTop: '1.5rem' }}>
//             <SearchableDropdown
//               label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_LABEL}
//               defaultText={COPY.TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT}
//               name="rejectReason"
//               id="caregiverSupportReturnToBoardIntakeReasonSelection"
//               options={dropdownOptions}
//               onChange={handleDropdownChange}
//               value={state.dropdown}
//               errorMessage={props.highlightInvalid &&
//                 !validDropdown(state.dropdown) ? 'You must select a reason for returning to intake' : null}
//             />
//             {state.dropdown === 'other' &&
//               <TextareaField
//                 label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER_REASON_TEXT_FIELD_LABEL}
//                 name="otherRejectReason"
//                 id="completeTaskOtherInstructions"
//                 onChange={(value) => setState({ otherInstructions: value })}
//                 value={state.otherInstructions}
//                 styling={marginTop(2)}
//                 textAreaStyling={setHeight(4.5)}
//                 errorMessage={props.highlightInvalid &&
//                   !validInstructions(state.otherInstructions) ? 'Return reason field is required' : null}
//               />}
//             <TextareaField
//               label={COPY.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TEXT_FIELD_LABEL}
//               name="instructions"
//               id="caregiverSupportReturnToBoardIntakeInstructions"
//               onChange={(value) => setState({ instructions: value })}
//               value={state.instructions}
//               styling={marginTop(2)}
//               maxlength={ATTORNEY_COMMENTS_MAX_LENGTH}
//               optional
//             />
//           </div>
//         )}
//       </React.Fragment>
//     );
//   };