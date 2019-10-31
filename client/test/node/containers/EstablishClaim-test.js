import React from 'react';

import { expect } from 'chai';
import { mount } from 'enzyme';

import { WrappingComponent } from '../../karma/establishClaim/WrappingComponent';
import { EstablishClaim, ASSOCIATE_PAGE } from '../../../app/containers/EstablishClaimPage/EstablishClaim';

import { findElementById } from '../../helpers';

let func = function() {
  // empty function
};

describe('EstablishClaim', () => {
  context('.render', () => {
    let wrapper;

    beforeEach(() => {
      /* eslint-disable camelcase */
      const task = {
        appeal: {
          vbms_id: '516517691',
          dispatch_decision_type: 'Remand',
          decisions: [
            {
              label: null
            }
          ],
          non_canceled_end_products_within_30_days: [],
          pending_eps: [],
          station_key: '397',
          regional_office_key: 'RO11'
        },
        user: 'a'
      };

      /* eslint-enable camelcase */

      const regionalOfficeCities = {
        RO11: {
          city: 'Pittsburgh',
          state: 'PA',
          timezone: 'America/New_York'
        }
      };

      wrapper = mount(
        <EstablishClaim
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

    context('navigation', () => {
      it('initially loads to decision page', () => {
        expect(wrapper.instance().history.location.pathname).to.equal('/decision');
        expect(wrapper.state().page).to.equal('decision');
      });

      it('redirects to decision if no existing EPs', (done) => {
        // Add a listener to the history object and look for the "go back" POP event
        let unlisten = wrapper.instance().history.listen((location, action) => {
          if (action === 'POP') {
            expect(wrapper.instance().history.location.pathname).to.equal('/decision');
            unlisten();
            done();
          }
        });

        // manually navigate to associate EP page
        // This simulates a user manually altering the URL
        wrapper.instance().history.push('associate');
      });
    });

    context('AssociateEP', () => {
      beforeEach(() => {
        wrapper.setState({ page: ASSOCIATE_PAGE });
      });

      it('shows cancel model', () => {
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);

        // click cancel to open modal
        findElementById(wrapper, 'button-Cancel').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(1);

        // Click go back and close modal
        findElementById(wrapper, 'Stop-Processing-Claim-button-id-0').simulate('click');
        expect(wrapper.find('.cf-modal-body')).to.have.length(0);
      });
    });
  });
});
