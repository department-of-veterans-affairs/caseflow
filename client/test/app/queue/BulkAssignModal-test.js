// import React from 'react';
// import { expect } from 'chai';
// import { mount } from 'enzyme';
// import sinon from 'sinon';

// import BulkAssignModal from '../../../app/queue/components/BulkAssignModal';

// describe('BulkAssignModal', () => {
//   let wrapper;
//   const assignFunction = () => ({});

//   let props = {
//     enableBulkAssign: true,
//     organizationUrl: 'something',
//     assignTasks: sinon.spy(assignFunction),
//     tasks: [
//       {
//         type: 'FirstType',
//         closestRegionalOffice: 'R017'
//       },
//       {
//         type: 'FirstType',
//         closestRegionalOffice: 'R016'
//       },
//       {
//         type: 'SecondType',
//         closestRegionalOffice: 'R017'
//       }
//     ]
//   };

//   context('renders', () => {
//     it('always renders button when enableBulkAssign is true', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       expect(wrapper.find('button.bulk-assign-button')).to.have.length(1);
//     });

//     it('does not render anything when enableBulkAssign is false', () => {
//       const newProps = Object.assign({}, props);

//       newProps.enableBulkAssign = false;
//       wrapper = mount(
//         <BulkAssignModal {...newProps} />
//       );

//       expect(wrapper.find('button.bulk-assign.button')).to.have.length(0);
//     });

//     it('only renders modal if button is clicked', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       expect(wrapper.find('.cf-modal')).to.have.length(0);

//       wrapper.find('button.bulk-assign-button').simulate('click');

//       expect(wrapper.find('.cf-modal')).to.have.length(1);
//     });

//     it('closes modal if Cancel is clicked', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');
//       wrapper.find('.cf-modal .cf-btn-link').simulate('click');

//       expect(wrapper.find('.cf-modal')).to.have.length(0);
//     });

//     it('closes modal if X is clicked', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');
//       wrapper.find('.cf-modal .cf-modal-close').simulate('click');

//       expect(wrapper.find('.cf-modal')).to.have.length(0);
//     });

//     it('does not assign tasks when there are errors', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');
//       expect(wrapper.find('.cf-modal')).to.have.length(1);

//       wrapper.find('.cf-modal .usa-button-secondary').simulate('click');
//       expect(wrapper.find('.cf-modal')).to.have.length(1);
//     });

//     it('returns errors for required fields', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');
//       expect(wrapper.find('.cf-modal')).to.have.length(1);

//       wrapper.find('.cf-modal .usa-button-secondary').simulate('click');

//       expect(wrapper.instance().generateErrors()).to.have.length(3);
//     });

//     it('assigns tasks when there are no errors', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');

//       const fieldValues = {
//         assignedUser: 'BVATWARNER',
//         regionalOffice: 'R017',
//         taskType: 'scheduleHearing',
//         numberOfTasks: '5'
//       };

//       wrapper.setState({ modal: fieldValues });
//       wrapper.find('.cf-modal .usa-button-secondary').simulate('click');

//       expect(props.assignTasks.calledOnce).to.equal(true);
//     });

//     it('correctly formats task types', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');

//       const options = wrapper.instance().generateTaskTypeOptions();

//       expect(options[1].value).to.have.string('FirstType');
//       expect(options[1].displayText).to.have.string('First Type');
//     });

//     it('returns unique task type options', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');

//       const options = wrapper.instance().generateTaskTypeOptions();

//       expect(options).to.have.length(3);
//       expect(options[0].value).to.eql(null);
//       expect(options[1].value).to.have.string('FirstType');
//       expect(options[2].value).to.have.string('SecondType');
//     });

//     it('returns unique regional offices', () => {
//       wrapper = mount(
//         <BulkAssignModal {...props} />
//       );

//       wrapper.find('button.bulk-assign-button').simulate('click');

//       const options = wrapper.instance().generateRegionalOfficeOptions();

//       expect(options).to.have.length(3);
//       expect(options[0].value).to.eql(null);
//       expect(options[1].value).to.have.string('R017');
//       expect(options[2].value).to.have.string('R016');
//     });
//   });

//   it('only shows tasks for given regionalOffice', () => {
//     wrapper = mount(
//       <BulkAssignModal {...props} />
//     );

//     wrapper.find('button.bulk-assign-button').simulate('click');

//     const fieldValues = {
//       assignedUser: 'BVATWARNER',
//       regionalOffice: 'R016',
//       taskType: null,
//       numberOfTasks: null
//     };

//     wrapper.setState({ modal: fieldValues });

//     const options = wrapper.instance().generateTaskTypeOptions();

//     expect(options).to.have.length(2);
//     expect(options[1].value).to.have.string('FirstType');
//   });
// });
