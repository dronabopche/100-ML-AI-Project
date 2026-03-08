# 👥 Employee Turnover Prediction Analysis

## 📌 Project Overview

This project focuses on predicting **employee turnover** using a structured dataset sourced from **Kaggle**.  
The objective is to build a **baseline Logistic Regression model** and improve it using **regularization techniques (L1 & L2)**, followed by a comprehensive comparison of model performance.

The project emphasizes **model interpretability, evaluation rigor, and comparative analysis**, making it suitable for academic work, interviews, and portfolio presentation.

---

## 🎯 Objectives

- Build a baseline Logistic Regression model for employee turnover prediction  
- Improve model performance using **L1 (Lasso)** and **L2 (Ridge)** regularization  
- Evaluate models using multiple classification metrics  
- Compare models visually and statistically  
- Recommend the best-performing model based on results  

---

## 📊 Dataset Information

- **Source:** Kaggle  
- **Dataset Size:** 1,350 rows × 16 columns  
- **Target Variable:** `Employee_Turnover`  
  - `0` → No Turnover  
  - `1` → Turnover  
- **Features:** 15 numerical employee-related metrics representing corporate scenarios  

> Dataset file used: `employee_turnover.csv`

---

## 🛠️ Technologies Used

- **Programming Language:** Python  
- **Libraries:**
  - NumPy
  - Pandas
  - Matplotlib
  - Seaborn
  - Scikit-learn  
- **Environment:** Jupyter Notebook  

---

## 🔍 Exploratory Data Analysis (EDA)

EDA was performed to understand data quality and target distribution:

- Dataset shape and data types inspection  
- Missing value analysis (no missing values found)  
- Target variable distribution analysis:
  - Nearly balanced classes (~50% turnover / ~50% no turnover)  
- Visualizations:
  - Bar chart of target counts  
  - Pie chart of target percentages  

Balanced data ensures reliable evaluation of classification models.

---

## ⚙️ Data Preprocessing

Key preprocessing steps include:

- Separating features and target variable  
- Standardizing features using **StandardScaler** (critical for regularization)  
- Stratified train-test split:
  - **50% Training**
  - **50% Testing**
  - Ensures class balance in both sets  

---

## 🤖 Models Implemented

### 1. Baseline Logistic Regression
**Why Logistic Regression?**
- Interpretable coefficients  
- Efficient training and prediction  
- Probabilistic outputs  
- Strong baseline for binary classification  

---

### 2. L1 Regularized Logistic Regression (Lasso)
- Encourages sparsity in coefficients  
- Performs implicit feature selection  
- Helps reduce model complexity  

---

### 3. L2 Regularized Logistic Regression (Ridge)
- Penalizes large coefficients  
- Prevents any single feature from dominating  
- Improves generalization  

---

## 📈 Model Evaluation Metrics

Each model was evaluated using:

- **Accuracy**
- **Precision**
- **Recall**
- **F1-Score**
- **AUC-ROC**
- **R² Score** (included for comparative insight)

---

## 📊 Performance Summary

| Model          | Accuracy | Precision | Recall | F1-Score | AUC-ROC | R² Score |
|----------------|----------|-----------|--------|----------|---------|----------|
| Baseline       | 85.78%   | 87.27%    | 83.63% | 85.41%   | 0.948   | 0.431    |
| L1 (Lasso)     | 85.93%   | 87.08%    | 84.23% | 85.63%   | 0.948   | 0.437    |
| L2 (Ridge)     | 85.78%   | 87.27%    | 83.63% | 85.41%   | 0.948   | 0.431    |

---

## 📉 Visual Analysis

The project includes:

- Feature importance visualization from the baseline model  
- Bar plots comparing all models across:
  - Accuracy
  - Precision
  - Recall
  - F1-Score
  - AUC-ROC
  - R² Score  

These visualizations make performance differences easy to interpret.

---

## ✅ Key Insights & Recommendation

- All three models perform strongly due to balanced data  
- **L1 Regularized Logistic Regression** achieves:
  - Slightly higher Accuracy
  - Best F1-Score
  - Highest R² Score  
- L1 regularization also provides **feature selection benefits**

📌 **Recommended Model:**  
**L1 (Lasso) Regularized Logistic Regression**

---

## 📂 Project Structure

```text
Employee-Turnover-Prediction/
│
├── employee_turnover.csv
├── Employee_Turnover_Analysis.ipynb
├── README.md
````

---

## 🚀 How to Run the Project

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/employee-turnover-prediction.git
   ```

2. Navigate to the project directory:

   ```bash
   cd employee-turnover-prediction
   ```

3. Launch Jupyter Notebook:

   ```bash
   jupyter notebook
   ```

4. Open and run:

   ```text
   Employee_Turnover_Analysis.ipynb
   ```

---

## 📌 Future Improvements

* Hyperparameter tuning using GridSearchCV
* ROC curve and Precision–Recall curve visualization
* Cross-validation for robustness
* Model deployment using Flask or FastAPI
* SHAP-based feature importance analysis

---

## 👤 Author

**Cherry**
Engineering Student | Machine Learning Enthusiast

---

## 📜 License

This project is intended for **educational purposes**.
You are free to use, modify, and distribute it with proper attribution.
