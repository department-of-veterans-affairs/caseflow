import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';

import { BrowserRouter } from 'react-router-dom';
import { MTVJudgeDisposition } from '../../../../app/queue/mtv/MTVJudgeDisposition';
import { tasks, attorneys, appeals } from './sample';

describe('CorrectionTypeModal', () => {
  const [task] = tasks;
  const [appeal] = appeals;

  context('renders', () => {
    it('default elements', () => {
      const wrapper = mount(
        <BrowserRouter>
          <MTVJudgeDisposition task={task} appeal={appeal} attorneys={attorneys} onSubmit={() => null} />
        </BrowserRouter>
      );

      const taskInstructions = wrapper.find('.mtv-task-instructions');
      const dispositionSelect = wrapper.find('.mtv-disposition-selection');
      const vacateTypeSelect = wrapper.find('.mtv-vacate-type');
      const instructions = wrapper.find('.mtv-decision-instructions');

      expect(taskInstructions.exists()).to.be.eql(true);
      expect(dispositionSelect.exists()).to.be.eql(true);
      expect(vacateTypeSelect.exists()).to.be.eql(false);
      expect(instructions.exists()).to.be.eql(true);
    });
  });
});
