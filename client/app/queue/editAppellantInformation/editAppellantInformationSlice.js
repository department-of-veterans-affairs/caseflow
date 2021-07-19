import { createSlice } from '@reduxjs/toolkit';
import ApiUtil from '../../util/ApiUtil';
import { mapAppellantDataToApi } from './utils';

const initialState = {
  claimant: {},
};

const editClaimantSlice = createSlice({
  name: 'editClaimant',
  initialState,
  reducers: {
    cancel: () => ({ ...initialState }),
    updateAppellantInformation: (_state, action) => {
      const { formData, appellantId, appealId } = action.payload;
      
      const _appellantPayload = mapAppellantDataToApi(formData);
      ApiUtil.patch(`/unrecognized_appellants/${appellantId}`, { data: _appellantPayload } ).then(
        (response) => {
          // CASEFLOW-1924
          window.location = `/queue/appeals/${appealId}`
        },
        // CASEFLOW-1925
        (error) => {
          console.log(error)
        }
      )

    },
    clearClaimant: (state) => {
      state.claimant = {};
    },
  },
});

export const {
  cancel,
  updateAppellantInformation,
  clearClaimant,
} = editClaimantSlice.actions;

export default editClaimantSlice.reducer;
