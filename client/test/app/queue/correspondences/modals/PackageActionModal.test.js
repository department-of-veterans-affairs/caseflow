import React from 'react';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import PackageActionModal from '../../../../../app/queue/correspondence/modals/PackageActionModal';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';
import { correspondenceData, packageDocumentTypeData } from '../../../../data/correspondence';

jest.mock('react-router', () => ({
  useHistory: () => ({
    push: jest.fn()
  })
}));

const mockCloseHandler = jest.fn();
let initialState = {
  reviewPackage: {
    correspondence: correspondenceData,
    packageDocumentType: packageDocumentTypeData
  }
};

const store = createStore(rootReducer, initialState, applyMiddleware(thunk));

const renderPackageActionModal = (dropdownType) => {
  render(
    <Provider store={store}>
      <PackageActionModal packageActionModal={dropdownType} closerhandler={mockCloseHandler} />
    </Provider>
  );
};

describe('PackageActionModal rendering', () => {
  it('renders the remove package action modal', () => {
    const fullName = correspondenceData.veteranFullName.toString();
    const fileNumber = correspondenceData.veteranFileNumber.toString();

    renderPackageActionModal('removePackage');

    expect(screen.getByText('Request package removal')).toBeInTheDocument();
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('Provide a reason for removal')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();
    // hacky way to match multi line dynamic text
    expect(screen.getByText(`${fullName}`, { exact: false })).toBeInTheDocument();
    expect(screen.getByText(`${fileNumber}`, { exact: false })).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();
    const textbox = screen.getByRole('textbox', { name: 'Provide a reason for removal' });

    userEvent.type(textbox, 'very good reason haha');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });

  it('renders the reassign package action modal', () => {
    const fullName = correspondenceData.veteranFullName.toString();
    const fileNumber = correspondenceData.veteranFileNumber.toString();

    renderPackageActionModal('reassignPackage');

    expect(screen.getByText('Request package reassignment')).toBeInTheDocument();
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('Provide a reason for reassignment')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();
    // hacky way to match multi line dynamic text
    expect(screen.getByText(`${fullName}`, { exact: false })).toBeInTheDocument();
    expect(screen.getByText(`${fileNumber}`, { exact: false })).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();
    const textbox = screen.getByRole('textbox', { name: 'Provide a reason for reassignment' });

    userEvent.type(textbox, 'very good reason haha');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });

  it('renders the split package action modal', () => {

    const fullName = correspondenceData.veteranFullName.toString();
    const fileNumber = correspondenceData.veteranFileNumber.toString();

    renderPackageActionModal('splitPackage');

    expect(screen.getByText('Request split package')).toBeInTheDocument();
    expect(screen.getByText('Veteran Details')).toBeInTheDocument();
    expect(screen.getByText('Select a reason for splitting this package')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();

    expect(screen.getByText(`${fullName}`, { exact: false })).toBeInTheDocument();
    expect(screen.getByText(`${fileNumber}`, { exact: false })).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();

    const radio1 = screen.getByRole('radio', { name: 'Package contains documents related to more than one person.' });

    userEvent.click(radio1);
    expect(radio1).toBeChecked();

    const radio2 = screen.getByRole('radio',
      { name: 'Package contains documents that must be processed by multiple business lines.' });

    userEvent.click(radio2);
    expect(radio2).toBeChecked();

    const otherRadioOption = screen.getByRole('radio', { name: 'Other' });

    userEvent.click(otherRadioOption);
    const textbox = screen.getByRole('textbox', { name: 'Reason for split' });

    expect(textbox).toBeInTheDocument();
    userEvent.type(textbox, 'test text for check');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });

  it('renders the merge package action modal', () => {

    renderPackageActionModal('mergePackage');

    expect(screen.getByText('Request merge')).toBeInTheDocument();
    expect(screen.getByText('Select a reason for merging this package.')).toBeInTheDocument();
    expect(screen.getByText('Non-NOD')).toBeInTheDocument();

    expect(screen.getByRole('button', { name: 'Confirm request' })).toBeDisabled();

    const radio1 = screen.getByRole('radio', { name: 'Duplicate documents' });

    userEvent.click(radio1);
    expect(radio1).toBeChecked();

    const radio2 = screen.getByRole('radio',
      { name: 'Documents received on the same date relating to the same issue(s)/appeal(s)' });

    userEvent.click(radio2);
    expect(radio2).toBeChecked();

    const otherRadioOption = screen.getByRole('radio', { name: 'Other' });

    userEvent.click(otherRadioOption);
    const textbox = screen.getByRole('textbox', { name: 'Reason for merge' });

    expect(textbox).toBeInTheDocument();
    userEvent.type(textbox, 'test text for check');
    expect(screen.getByRole('button', { name: 'Confirm request' })).not.toBeDisabled();

  });
});
