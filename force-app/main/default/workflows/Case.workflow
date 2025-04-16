<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Alert_for_approval</fullName>
        <description>Alert for approval</description>
        <protected>false</protected>
        <recipients>
            <recipient>finalproject@gmail.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Email_Templates/case_Approval_template</template>
    </alerts>
    <alerts>
        <fullName>Due_date_email_alert</fullName>
        <description>Due date email alert</description>
        <protected>true</protected>
        <recipients>
            <recipient>finalproject@gmail.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Email_Templates/case_Due_date</template>
    </alerts>
    <alerts>
        <fullName>Rejection_email</fullName>
        <description>Rejection email</description>
        <protected>false</protected>
        <recipients>
            <recipient>finalproject@gmail.com</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>Email_Templates/case_Rejection_Approval</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approval_Status</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Approval Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_C</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approval Status C</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Submit_status</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending</literalValue>
        <name>Submit status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Submit_staus</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending</literalValue>
        <name>Submit staus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
