import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { MTVJudgeDisposition } from '../../../../app/queue/mtv/MTVJudgeDisposition';
import { tasks, attorneys } from './sample';

describe('CorrectionTypeModal', () => {
  const [task] = tasks;
  const [attorney] = attorneys;

  context('renders', () => {
    it('default elements', () => {
      const wrapper = mount(<MTVJudgeDisposition task={task} attorneys={attorneys} onSubmit={() => null} />);

      const taskInstructions = wrapper.find('.mtv-task-instructions');
      const dispositionSelect = wrapper.find('.mtv-disposition-selection');
      const vacateTypeSelect = wrapper.find('.mtv-vacate-type');
      const instructions = wrapper.find('.mtv-decision-instructions');

      expect(taskInstructions.exists()).to.be.eql(true);
      expect(dispositionSelect.exists()).to.be.eql(true);
      expect(vacateTypeSelect.exists()).to.be.eql(false);
      expect(instructions.exists()).to.be.eql(true);
    });

    // Enzyme doesn't yet allow use of state via React hooks
    // it('vacate type type only when disposition=granted', () => {
    //   const wrapper = mount(<MTVJudgeDisposition task={task} attorneys={attorneys} onSubmit={() => null} />);
    //   const dispositionSelect = wrapper.find('.mtv-disposition-selection').hostNodes();

    //   expect(wrapper.find('.mtv-vacate-type').exists()).to.be.eql(false);

    //   dispositionSelect.find('#disposition_granted').simulate('change', { target: { value: 'granted' } });

    //   expect(wrapper.find('.mtv-vacate-type').exists()).to.be.eql(true);
    // });
  });
});
