import { LightningElement, wire, track } from 'lwc';
import getProjects from '@salesforce/apex/ProjectDashboardController.getProjects';
import getCaseStatusCounts from '@salesforce/apex/ProjectDashboardController.getCaseStatusCounts';
import getResourceUtilization from '@salesforce/apex/ProjectDashboardController.getResourceUtilization';
import getProjectProgress from '@salesforce/apex/ProjectDashboardController.getProjectProgress';
import { loadScript } from "lightning/platformResourceLoader";
import ChartJS from "@salesforce/resourceUrl/ChartJS";

export default class ProjectDashboard extends LightningElement {
    // Track UI variables
    @track projectOptions = [];
    @track selectedProject = '';
    @track caseStatusData = [];
    @track resourceUtilizationData = [];
    @track projectProgress = 0;
    chartLoaded = false; // Flag to ensure Chart.js is loaded only once

    // Chart instances
    caseChart;
    resourceChart;
    progressChart;

    // Wire method to fetch projects from Apex controller
    @wire(getProjects)
    wiredProjects({ error, data }) {
        if (data) {
            // Map project names into a format suitable for a dropdown list
            this.projectOptions = data.map((proj) => ({
                label: proj.Name,
                value: proj.Name
            }));
        } else if (error) {
            console.error("Error fetching projects: ", error);
        }
    }

    // Handle project selection change
    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        console.log("Selected Project:", this.selectedProject);
        
        // Fetch related data based on the selected project
        this.fetchCaseStatusData();
        this.fetchResourceUtilizationData();
        this.fetchProjectProgress();
    }

    // Fetch case status data for the selected project
    fetchCaseStatusData() {
        getCaseStatusCounts({ projectName: this.selectedProject })
            .then((data) => {
                if (!data || data.length === 0) {
                    console.warn("No case status data found.");
                    return;
                }
                // Map data into a chart-friendly format
                this.caseStatusData = data.map((record) => ({
                    label: record.Status,
                    value: record.totalCases
                }));
                this.renderCharts();
            })
            .catch((error) => {
                console.error("Error fetching case status data: ", error);
            });
    }

    // Fetch resource utilization data for the selected project
    fetchResourceUtilizationData() {
        getResourceUtilization({ projectName: this.selectedProject })
            .then((data) => {
                console.log("Raw Resource Data:", data);
                if (!data || data.length === 0) {
                    console.warn("No resource utilization data found.");
                    return;
                }
                // Transform data for charting
                this.resourceUtilizationData = data.map((record) => ({
                    label: record.Name,
                    value: record.support36zero__Allocation_Percentage__c
                }));
                console.log("Mapped Resource Data:", this.resourceUtilizationData);
                this.renderCharts();
            })
            .catch((error) => {
                console.error("Error fetching resource utilization data: ", error);
            });
    }

    // Fetch project progress percentage
    fetchProjectProgress() {
        getProjectProgress({ projectName: this.selectedProject })
            .then((progress) => {
                this.projectProgress = progress;
                console.log("Project Progress:", this.projectProgress);
                this.renderCharts();
            })
            .catch((error) => {
                console.error("Error fetching project progress: ", error);
            });
    }

    // Lifecycle hook: Ensure Chart.js is loaded before rendering charts
    renderedCallback() {
        if (!this.chartLoaded) {
            loadScript(this, ChartJS)
                .then(() => {
                    console.log("Chart.js loaded successfully.");
                    this.chartLoaded = true;
                    this.renderCharts();
                })
                .catch(error => console.error("Error loading Chart.js: ", error));
        }
    }

    // Render charts with updated data
    renderCharts() {
        console.log("Rendering Charts...");

        // Select canvas elements for charts
        const caseCanvas = this.template.querySelector(".caseStatusChart");
        const resourceCanvas = this.template.querySelector(".resourceUtilizationChart");
        const progressCanvas = this.template.querySelector(".progressChart");

        // Ensure necessary elements are available
        if (!this.chartLoaded || (!caseCanvas && !resourceCanvas && !progressCanvas)) {
            console.warn("Skipping chart rendering: Required elements missing.");
            return;
        }

        // Destroy existing charts before re-rendering
        if (this.caseChart) this.caseChart.destroy();
        if (this.resourceChart) this.resourceChart.destroy();
        if (this.progressChart) this.progressChart.destroy();

        // Render case status bar chart
        if (this.caseStatusData.length > 0 && caseCanvas) {
            this.caseChart = new Chart(caseCanvas.getContext("2d"), {
                type: "bar",
                data: {
                    labels: this.caseStatusData.map((d) => d.label),
                    datasets: [{
                        label: "Cases",
                        data: this.caseStatusData.map((d) => d.value),
                        backgroundColor: ["red", "blue", "green", "orange", "purple"]
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }

        // Render resource utilization doughnut chart
        if (this.resourceUtilizationData.length > 0 && resourceCanvas) {
            console.log("Rendering Resource Chart...");
            this.resourceChart = new Chart(resourceCanvas.getContext("2d"), {
                type: "doughnut",
                data: {
                    labels: this.resourceUtilizationData.map((d) => d.label),
                    datasets: [{
                        data: this.resourceUtilizationData.map((d) => d.value),
                        backgroundColor: ["red", "green", "blue"]
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }

        // Render project progress doughnut chart
        if (this.selectedProject && progressCanvas) {
            this.progressChart = new Chart(progressCanvas.getContext("2d"), {
                type: "doughnut",
                data: {
                    labels: ["Completed", "Remaining"],
                    datasets: [{
                        data: [this.projectProgress, 100 - this.projectProgress],
                        backgroundColor: ["green", "gray"]
                    }]
                },
                options: { responsive: true, maintainAspectRatio: false }
            });
        }
    }
}