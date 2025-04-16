/**
 * @description       : LWC component to handle Case Resolution modal.
 *                      It triggers when a Case status changes to 'Done' without a resolution.
 *                      Ensures users provide a resolution before proceeding.
 * @author            : [Nasrul Hasan]
 * @group             : 
 * @last modified on  : 02-14-2025
 * last modified by  : [Nasrul Hasan]
 **/

import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import CASE_RESOLUTION from '@salesforce/schema/Case.Resolution__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseResolutionModal extends LightningElement {
    @api recordId; // Record ID passed from the parent component
    @track showResolutionModal = false; // Boolean flag to control modal visibility
    previousStatus = ''; // Variable to store the previous status of the case
    resolution = ''; // Stores resolution input from user

    // Lifecycle hook: Runs when component is added to the DOM
    connectedCallback() {
        this.handleUnload = this.handleUnload.bind(this); // Ensures proper reference to 'this'
        window.addEventListener('beforeunload', this.handleUnload); // Handles page unload events
    }

    // Lifecycle hook: Runs when component is removed from the DOM
    disconnectedCallback() {
        window.removeEventListener('beforeunload', this.handleUnload);
    }

    // Handle browser unload event
    handleUnload(event) {
        if (this.showResolutionModal) {
            this.revertStatus(); // Revert status if modal is open
            event.preventDefault();
            event.returnValue = ''; // Required for showing the browser's warning dialog
        }
    }

    // Wire service to get case record details
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [CASE_STATUS, CASE_RESOLUTION] 
    })
    caseRecord({ data, error }) {
        if (data) {
            const currentStatus = getFieldValue(data, CASE_STATUS);
            const currentResolution = getFieldValue(data, CASE_RESOLUTION);

            console.log('Current Status:', currentStatus);
            console.log('Previous Status:', this.previousStatus);
            console.log('Current Resolution:', currentResolution);

            // Store previous status before it changes to 'Done'
            if (currentStatus !== 'Done' && this.previousStatus !== currentStatus) {
                this.previousStatus = currentStatus;
            }

            const isStatusChanged = this.previousStatus && this.previousStatus !== currentStatus;

            // Open modal if status changes to 'Done' and resolution is empty
            if (isStatusChanged && currentStatus === 'Done' && this.previousStatus !== 'Done') {
                this.showResolutionModal = true;
            }

            // Force modal to open if resolution is blank
            // if (!currentResolution) {
            //     this.showResolutionModal = true;
            // }
        } else if (error) {
            this.handleError(error);
        }
    }

    // Handles user input in resolution field
    handleResolutionChange(event) {
        this.resolution = event.target.value;
    }

    // Handles form submission
    async handleSubmit() {
        if (!this.resolution?.trim()) {
            this.showToast('Error', 'Resolution is required', 'error');
            await this.revertStatus();
            return;
        }

        const fields = {
            Id: this.recordId,
            [CASE_RESOLUTION.fieldApiName]: this.resolution
        };

        try {
            await updateRecord({ fields });
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.showResolutionModal = false;
            this.showToast('Success', 'Resolution added!', 'success');
        } catch (error) {
            this.handleError(error);
        }
    }

    // Handles cancel action
    async handleCancel() {
        console.log('User canceled. Reverting status...');
        await this.revertStatus();
        this.showResolutionModal = false;
        window.location.reload(); // Force page reload to reflect changes
    }

    // Reverts status if resolution is not provided
    async revertStatus() {
        if (this.previousStatus && this.previousStatus !== 'Done') {
            const fields = {
                Id: this.recordId,
                [CASE_STATUS.fieldApiName]: this.previousStatus
            };

            try {
                await updateRecord({ fields });
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

                this.showToast('Info', `Status reverted to '${this.previousStatus}'`, 'info');

                // Reset previous status so it updates properly next time
                this.previousStatus = ''; 
            } catch (error) {
                this.handleError(error);
            }
        }
    }

    // Displays a toast notification
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Handles errors and displays an error toast
    handleError(error) {
        console.error('Error:', error);
        this.showToast('Error', error.body?.message || 'Unknown error', 'error');
    }
}