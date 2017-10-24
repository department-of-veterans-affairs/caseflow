// Pdf actions

export const selectCurrentPdfLocally = (docId) => ({
    type: Constants.SELECT_CURRENT_VIEWER_PDF,
    payload: {
      docId
    }
  });
  
  export const selectCurrentPdf = (docId) => (dispatch) => {
    ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ).
      catch((err) => {
        // eslint-disable-next-line no-console
        console.log('Error marking as read', docId, err);
      });
  
    dispatch(
      selectCurrentPdfLocally(docId)
    );
  };


export const setOpenedAccordionSections = (openedAccordionSections, prevSections) => ({
  type: Constants.SET_OPENED_ACCORDION_SECTIONS,
  payload: {
    openedAccordionSections
  },
  meta: {
    analytics: (triggerEvent) => {
      const addedSectionKeys = _.difference(openedAccordionSections, prevSections);
      const removedSectionKeys = _.difference(prevSections, openedAccordionSections);

      addedSectionKeys.forEach(
        (newKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'opened-accordion-section', newKey)
      );
      removedSectionKeys.forEach(
        (oldKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'closed-accordion-section', oldKey)
      );
    }
  }
});

