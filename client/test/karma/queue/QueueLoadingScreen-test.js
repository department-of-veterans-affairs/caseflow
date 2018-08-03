import { expect } from 'chai';
import { associateTasksWithAppeals } from '../../../app/queue/utils';

const serverData = {
  tasks: {
    data: [
      {
        attributes: {
          added_by_css_id: 'BVANKUVALIS',
          added_by_name: 'Nash X Kuvalis',
          aod: false,
          appeal_id: 3,
          assigned_by_first_name: 'Stephen',
          assigned_by_last_name: 'Casper',
          assigned_on: '2018-08-02T17:37:03.000Z',
          assigned_to_pg_id: 130,
          case_type: 'Post Remand',
          docket_date: '2008-08-31T00:00:00.000Z',
          docket_name: 'Legacy',
          docket_number: '6182238',
          document_id: '12345-12345678',
          due_on: '2018-08-11T00:00:00.000Z',
          external_appeal_id: '3625593',
          issue_count: 6,
          paper_case: false,
          previous_task: {
            assigned_on: '2018-08-02T17:37:03.000Z'
          },
          task_id: '3625593-2018-07-11',
          task_type: 'Review',
          user_id: 'BVANKUVALIS',
          veteran_file_number: '767574947',
          veteran_name: 'Mills, Beulah, J',
          work_product: 'OTD'
        },
        id: '3625593',
        type: 'judge_legacy_tasks'
      }
    ]
  }
};

describe('QueueLoadingScreen', () => {
  it('associates queue decisions/appeals and tasks', () => {
    const { tasks } = associateTasksWithAppeals(serverData);

    expect(tasks).to.deep.equal({
      '3625593-2018-07-11': {
        appealId: 3,
        externalAppealId: '3625593',
        assignedOn: '2018-08-02T17:37:03.000Z',
        dueOn: '2018-08-11T00:00:00.000Z',
        userId: 'BVANKUVALIS',
        assignedToPgId: 130,
        addedByName: 'Nash X Kuvalis',
        addedByCssId: 'BVANKUVALIS',
        taskId: '3625593-2018-07-11',
        taskType: 'Review',
        documentId: '12345-12345678',
        assignedByFirstName: 'Stephen',
        assignedByLastName: 'Casper',
        workProduct: 'OTD',
        previousTaskAssignedOn: '2018-08-02T17:37:03.000Z'
      }
    });
  });
});
