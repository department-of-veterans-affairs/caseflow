import React from 'react';

import { mount } from 'enzyme';

// Component to be tested
import { EstablishClaim, ASSOCIATE_PAGE } from 'app/containers/EstablishClaimPage/EstablishClaim';

// Test helpers
import { WrappingComponent } from 'test/app/establishClaim/WrappingComponent';
import { findElementById } from 'test/helpers';
import { task, regionalOfficeCities } from 'test/data';

let func = function() {
  // empty function
};

describe('EstablishClaim', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(
      <EstablishClaim
        slowReRendersAreOk
        regionalOfficeCities={regionalOfficeCities}
        pdfLink=""
        pdfjsLink=""
        handleAlert={func}
        handleAlertClear={func}
        task={task}
      />,
      {
        wrappingComponent: WrappingComponent
      }
    );
  });

  describe('navigation', () => {
    test('initially loads to decision page', () => {
      expect(wrapper.instance().history.location.pathname).toBe('/decision');
      expect(wrapper.state().page).toBe('decision');
    });

    test('redirects to decision if no existing EPs', () => {
      return new Promise((done) => {
        // Add a listener to the history object and look for the "go back" POP event
        let unlisten = wrapper.instance().history.listen((location, action) => {
          if (action === 'POP') {
            expect(wrapper.instance().history.location.pathname).toBe('/decision');
            unlisten();
            done();
          }
        });

        // manually navigate to associate EP page
        // This simulates a user manually altering the URL
        wrapper.instance().history.push('associate');
      });
    });
  });

  describe('AssociateEP', () => {
    beforeEach(() => {
      wrapper.setState({ page: ASSOCIATE_PAGE });
    });

    test('shows cancel model', () => {
      expect(wrapper.find('.cf-modal-body')).toHaveLength(0);

      // click cancel to open modal
      findElementById(wrapper, 'button-Cancel').simulate('click');
      expect(wrapper.find('.cf-modal-body')).toHaveLength(1);

      // Click go back and close modal
      findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
      expect(wrapper.find('.cf-modal-body')).toHaveLength(0);
    });
  });
});
