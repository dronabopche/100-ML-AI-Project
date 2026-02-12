# ML_To_Train

A structured repository containing multiple Machine Learning projects with a consistent and reusable folder architecture.

Each project includes:

* Dataset(s)
* Trained model(s)
* Source code (API + preprocessing + output)
* Notebook / experimentation file

This repository is designed so every ML project follows the same structure, making it easy to maintain and reuse for future projects.

---

## 📌 Projects Included

1. Creditwise Loan Approval
2. Employee Retention
3. Heart Health Risk Predictor
4. House Price Predictor
5. Iris Flower Predictor
6. Legally Chatbot
7. Smart Ambulance Rapid Response
8. Smart Car Clustering System
9. Smart Soap Prediction

---

## 📂 Repository Structure (High-Level)

```
ML2Train/
│
├── Creditwise_Loan_Approval/
├── Employee_Retention/
├── Heart_Health_Risk_Predictor/
├── House_Price_Predictor/
├── Iris_Flower_Predictor/
├── Legally_Chatbot/
├── Smart_Ambulance_Rapid_Response/
├── Smart_Car_Clustering_System/
└── Smart_Soap_Prediction/
```

---

## 📂 Standard Structure Inside Every Project

Each project follows this exact structure:

```
Project_Name/
│
├── Dataset/
│   └── <dataset files>.csv
│
├── Models/
│   └── <trained model files>
│
├── SRC/
│   ├── Output/
│   │   └── index.html
│   │
│   ├── Processing/
│   │   └── preprocessing.py
│   │
│   └── App.py
│
└── <Project Notebook>.ipynb
```

---

## 📌 Folder Explanation

### Dataset/

* Contains raw datasets used in training.
* Naming rule: dataset file names should be clean and readable.
* No underscores required.
* Example:

  * smart car customer.csv
  * employee retention.csv

---

### Models/

* Contains trained model files.
* Examples:

  * .pkl
  * .joblib
  * .h5
  * saved pipelines

---

### SRC/

This folder contains the complete API pipeline.

#### SRC/App.py

* Entry point of the project.
* Runs the API.
* Handles:

  * request input
  * preprocessing call
  * model inference
  * response output

#### SRC/Processing/

* All preprocessing logic is stored here.
* Includes:

  * missing value handling
  * encoding
  * scaling
  * feature transformations

#### SRC/Output/

* Contains output UI (frontend).
* The output is usually shown in:

  * index.html
* Displays final results like:

  * risk score
  * prediction class
  * timestamp / confidence

---

## 📌 Naming Convention Rules

### Project Folder Naming

All project folder names follow:

* Title Case
* Words separated by underscore `_`

Example:

* Creditwise_Loan_Approval
* Smart_Car_Clustering_System
* Heart_Health_Risk_Predictor

---

### Dataset Naming

Dataset file names follow:

* Normal readable words
* Spaces allowed
* No underscores required

Example:

* smart car customer.csv
* loan approval.csv

---

### Notebook Naming

Notebook name matches the project name in readable format.

Example:

* Smart Car Clustering System.ipynb
* Creditwise Loan Approval.ipynb

---

## 📌 API Flow (Standard for All Projects)

Every project API works like this:

1. Input JSON comes into App.py
2. Data goes to SRC/Processing/
3. Missing values are handled (filled with constants or rules)
4. Data is passed to the model from Models/
5. Model returns prediction / score
6. Output is returned:

   * as JSON response
   * and/or displayed in SRC/Output/index.html

---

## Running Any Project

Go into the project folder and run:

```bash
cd Project_Name/SRC
python App.py
```
