
#🩸 BloodSense AI – Blood Report Analysis

BloodSense AI is an intelligent blood report analysis feature built with Flutter. It extracts biomarker values from blood report images and PDF documents, compares the extracted values against predefined clinical reference ranges, identifies abnormal markers, detects potential health-risk patterns, and provides personalized lifestyle recommendations.

The feature also supports manual blood report entry, allowing users to enter their test results without uploading a document.

#📌 Table of Contents

Overview

Key Features

Supported Input Methods

System Workflow

1. Image-Based Blood Report Extraction

2. PDF-Based Blood Report Extraction

3. Manual Blood Report Entry

Blood Marker Normalization

Reference Range Evaluation

Health Risk Detection

Lifestyle Recommendations

Results Dashboard

PDF Report Generation

Recent Reports and Temporary Storage

Technology Stack

Project Structure

CSV Dataset Structure

Installation and Setup

Important Implementation Details

Limitations

Medical Disclaimer

Future Improvements

#🔍 Overview

BloodSense AI simplifies the process of understanding blood test reports.

Traditional blood reports contain several laboratory parameters, numerical values, measurement units, and reference intervals. Understanding these values can be difficult for users without medical knowledge.

BloodSense AI processes blood report information through a multi-stage pipeline:

Extracts text and biomarker values from uploaded reports using OCR.

Identifies and standardizes biomarker names.

Extracts numerical test values.

Compares values against predefined reference ranges.

Classifies markers as Normal, High, or Low.

Detects combinations of abnormal markers associated with potential health-risk patterns.

Provides lifestyle recommendations for abnormal markers.

Generates a structured results dashboard and downloadable PDF report.

The application uses a shared analysis engine for image uploads, PDF uploads, and manual entry.

✨ Key Features

Image Upload: Upload blood report images in supported image formats.

PDF Upload: Extract information from multi-page PDF blood reports.

Manual Entry: Enter patient details and blood marker values manually.

OCR-Based Extraction: Extract laboratory text using Google ML Kit Text Recognition.

Marker Recognition: Match different laboratory naming conventions using a synonym dataset.

Reference Range Comparison: Evaluate biomarker values against stored reference intervals.

Gender-Based Evaluation: Use gender-specific reference ranges where available.

Abnormal Marker Detection: Identify high and low biomarker values.

Health-Risk Pattern Detection: Identify combinations of abnormal markers using predefined rules.

Lifestyle Recommendations: Display foods to add, foods to avoid, and exercise suggestions.

Detailed Biomarker View: Show individual biomarker results and their interpretations.

Health Summary: Present an overall summary of evaluated markers.

PDF Report Generation: Generate a downloadable report containing analysis results.

Recent Reports: Save and retrieve temporary reports locally.

Shared Results Dashboard: Display results consistently regardless of the input method.

📥 Supported Input Methods

BloodSense AI supports three ways to provide blood report information.

Input Method

Description

Processing

Image Upload

Upload a photograph or scanned image of a blood report

OCR extraction

PDF Upload

Upload a laboratory PDF report

PDF page conversion followed by OCR

Manual Entry

Select markers and enter their values

Direct numerical processing

All three input methods ultimately use the same BloodSense evaluation and results-mapping logic.

🔄 System Workflow

flowchart TD
    A[Start BloodSense AI] --> B{Choose Input Method}

    B --> C[Upload Image]
    B --> D[Upload PDF]
    B --> E[Manual Entry]

    C --> F[Google ML Kit OCR]
    D --> G[Convert PDF Pages to Images]
    G --> F
    E --> H[Collect Manual Marker Values]

    F --> I[Extract Marker Names and Values]
    H --> J[Manual Marker Data]

    I --> K[Marker Normalization]
    J --> K

    K --> L[Reference Range Evaluation]
    L --> M[Normal / High / Low Classification]

    M --> N[Health Risk Detection]
    N --> O[Lifestyle Recommendations]

    O --> P[Results Mapper]
    P --> Q[Health Summary]
    P --> R[Biomarker Results]

    Q --> S[Shared Results Dashboard]
    R --> S

    S --> T[Generate PDF Report]
    S --> U[Recent Reports]

1. Image-Based Blood Report Extraction

BloodSense AI supports image-based blood report analysis using Google ML Kit Text Recognition.

Processing Steps

The user selects a blood report image from the gallery or captures a photograph.

The selected image is passed to the OCR extraction module.

Google ML Kit recognizes text within the image.

Extracted text lines are processed to identify biomarker names and numerical values.

Text lines are grouped into rows using their vertical bounding-box positions.

The extracted marker names are normalized.

Numerical values are passed to the evaluation engine.

OCR Processing

The extraction process includes:

Text recognition from report images.

Grouping text lines into rows based on vertical positions.

Removing unnecessary characters.

Cleaning numerical values.

Detecting gender information from recognized text.

Extracting the first relevant numerical value from a marker row.

Handling absolute blood cell counts.

Numerical Value Cleaning

The OCR processing handles common formatting issues, including:

Thousands separators.

Spaces within numerical values.

Comma and decimal formatting.

Scientific-style count representations such as 10^3.

Absolute cell count markers.

Absolute count markers are identified using the _absolute suffix where applicable.

Gender Detection

The OCR extraction module attempts to identify gender from report text.

It recognizes common text variations such as:

Female-related terms and prefixes.

Male-related terms and prefixes.

If gender cannot be identified, the existing extraction flow uses its configured default gender.

2. PDF-Based Blood Report Extraction

PDF reports are processed by converting their pages into images before running OCR.

Processing Steps

The user selects a PDF blood report.

The PDF handler loads the selected document.

Each PDF page is rendered as an image.

Pages are rendered at an increased resolution to support OCR accuracy.

Generated page images are passed to the image extraction pipeline.

Extracted biomarker values are evaluated using the shared BloodSense engine.

PDF Processing Technology

The implementation uses:

file_picker for selecting PDF files.

pdfx for rendering PDF pages.

Temporary image files for OCR processing.

Google ML Kit Text Recognition for text extraction.

Multi-Page Support

The PDF processing pipeline supports reports containing multiple pages.

Each page is converted into an image, and the extracted marker data is combined before reference-range evaluation.

3. Manual Blood Report Entry

BloodSense AI also supports manual blood report entry.

This is useful when:

The report image is unclear.

OCR cannot recognize certain markers.

The user wants to enter laboratory values directly.

A digital report is unavailable.

Manual Entry Workflow

The manual entry interface follows a three-step process.

Step 1 – Patient Details

The user enters:

Full name.

Age.

Gender.

Report date.

Step 2 – Select Blood Markers

The user selects the markers available in the report.

Markers are organized into categories such as:

Haematology.

Biochemistry.

Lipid Profile.

Others.

The interface also supports marker search.

Step 3 – Enter Test Values

The user enters numerical values for the selected markers.

The application validates the entered values before starting analysis.

Manual Processing

Manual values are converted into a marker-value map and passed to the same processing function used by the BloodSense evaluation engine.

This ensures that manually entered values are evaluated using the same reference-range and risk-detection logic as OCR-extracted values.

🔤 Blood Marker Normalization

Laboratory reports often use different names and abbreviations for the same biomarker.

For example:

Laboratory Name

Standard Marker

Hb

Hemoglobin

Hgb

Hemoglobin

A1c

HbA1c

FBS

Glucose Fasting

PLT

Platelet Count

Erythrocyte Count

RBC

BloodSense AI uses a marker synonym dataset to standardize these variations.

Normalization Process

The extracted or manually entered marker name is received.

The name is converted into a standardized format.

Special characters and unnecessary spaces are removed for matching.

The synonym dataset is searched.

The corresponding standard marker name is returned.

The standardized marker is passed to the evaluation engine.

Main File

normalizer.dart

The normalization module contains:

buildSynonymMap()

normalizeMarker()

This makes marker matching more consistent across different laboratory report formats.

📊 Reference Range Evaluation

After marker normalization, BloodSense AI compares each numerical result against the reference ranges stored in the clinical dataset.

Reference Range Dataset

assets/blood_report/reference_ranges.csv

The dataset contains biomarker information and corresponding reference boundaries.

The evaluation engine uses:

Marker name.

Measured value.

Gender.

Lower reference boundary.

Upper reference boundary.

Evaluation Logic

For markers with lower and upper boundaries:

Condition

Classification

Value below lower boundary

Low

Value within reference boundaries

Normal

Value above upper boundary

High

Some biomarkers use one-sided reference limits, depending on how the reference data is defined.

Gender-Specific Reference Ranges

Where available, the evaluator uses separate reference intervals for male and female patients.

This is important because certain blood parameters have different reference intervals depending on gender.

Main File

evaluator.dart

The evaluation function:

evaluateMarker()

compares the marker value with the corresponding reference row and returns its evaluation status.

⚠️ Health Risk Detection

BloodSense AI includes a rule-based health-risk detection engine.

Instead of evaluating each abnormal marker in isolation, the engine can identify combinations of abnormal markers associated with predefined health-risk patterns.

Examples of Evaluated Patterns

The existing rules include patterns related to:

Metabolic health.

Cardiovascular health.

Kidney function.

Liver function.

Thyroid function.

Anaemia-related patterns.

Gout-related patterns.

Vitamin deficiencies.

How It Works

Evaluated marker results are received.

Marker statuses are checked.

High and low markers are identified.

Related markers are grouped according to predefined rules.

Matching risk patterns are returned.

Associated reasons and lifestyle information are included where available.

Main File

risk_engine.dart

Main function:

detectHealthRisks()

The engine uses predefined conditions and marker combinations. It is a rule-based system, not a machine-learning diagnostic model.

🥗 Lifestyle Recommendations

BloodSense AI provides lifestyle recommendations for abnormal biomarkers using a structured CSV dataset.

Dataset

assets/blood_report/lifestyle.csv

The dataset contains marker-specific recommendations for high and low results.

Recommendation Categories

Foods to Add

Food suggestions associated with the selected abnormal marker.

Foods to Avoid

Food items that may be advisable to limit based on the marker's evaluation.

Recommended Exercise

Exercise suggestions associated with the marker.

Exercise to Avoid

Activities that may need caution depending on the recommendation data.

Lifestyle Focus

Additional lifestyle guidance associated with the marker.

Recommendation Matching

The application matches evaluated biomarker names with the lifestyle dataset.

The marker synonym mapping helps account for naming differences between laboratory reports and recommendation records.

Recommendations are displayed only when matching data is available.

📱 Results Dashboard

After analysis, the application displays the processed results through a shared Results Page.

The same results interface is used for image uploads, PDF uploads, and manual entry.

Results Include

Overall health summary.

Total evaluated markers.

Normal marker count.

High marker count.

Low marker count.

Biomarker result cards.

Marker status indicators.

Health-risk patterns.

Lifestyle recommendations.

Detailed Biomarker View

Users can select an individual biomarker to view more information.

The detailed page includes:

Result overview.

Measured value.

Reference range.

Severity or status.

Clinical interpretation.

Related health-risk patterns.

Foods to add and avoid.

Exercise recommendations.

Lifestyle focus.

Health guidance.

Medical disclaimer.

The detailed recommendations are based on the marker's evaluation and the available lifestyle dataset.

📄 PDF Report Generation

BloodSense AI can generate a structured PDF report containing the evaluated results.

PDF Report Contents

Biomarker names.

Measured values.

Measurement units.

Reference ranges.

Evaluation status.

Health summary information.

The PDF generation module uses the processed results from the shared results models.

Main File

blood_report_pdf_service.dart

The generated report is available for the user's report workflow and can be saved with the corresponding temporary report record.

🗂 Recent Reports and Temporary Storage

BloodSense AI includes a Recent Reports feature for accessing previously analyzed reports.

Temporary Storage

The report storage implementation uses:

TemporaryBloodReport

TemporaryReportStorageService

AES-GCM encryption.

Flutter Secure Storage.

Stored Information

A temporary report record can contain:

Report ID.

Input type.

Display name.

Biomarker parameters.

Health summary.

Report generation date.

Expiry date.

Original document path, when applicable.

Generated PDF path.

Supported Report Types

Image-based reports.

PDF-based reports.

Manually entered reports.

Report Expiry

Reports are configured with a temporary retention period of 24 hours.

The storage service manages the temporary report records and their retrieval.

Important: This implementation uses local encrypted temporary storage. It does not mean that the original blood report or generated PDF is automatically uploaded to Firebase.

🛠 Technology Stack

Technology

Purpose

Flutter

Cross-platform application development

Dart

Application programming language

Google ML Kit Text Recognition

OCR-based text extraction

image_picker

Selecting or capturing report images

file_picker

Selecting PDF documents

pdfx

Converting PDF pages into images

CSV datasets

Reference ranges, synonyms, lifestyle recommendations

Flutter Secure Storage

Secure local key storage

AES-GCM

Encryption of temporary report storage

path_provider

Accessing application directories

uuid

Generating unique report identifiers

Firebase

Backend services used by the wider application
