export const getStateProperty = (state, modelType, key) => {
  switch (modelType) {
  case 'docket_note':
  case 'docket_transcript_required':
  case 'docket_dropdown_action': {
    const [, date, index,, property] = key.split('.');

    return state.dockets[date].hearings_hash[index][property];
  }
  default: return null;
  }
};
