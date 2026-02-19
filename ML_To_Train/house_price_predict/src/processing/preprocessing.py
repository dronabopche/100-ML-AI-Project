import json
import numpy as np
import google.genai as genai


# =========================
# 1) FINAL MODEL FEATURES
# =========================
FINAL_FEATURE_ORDER = [
    "MSSubClass",
    "LotArea",
    "OverallCond",
    "YearBuilt",
    "TotalBsmtSF",

    "MSZoning_FV",
    "MSZoning_RH",
    "MSZoning_RL",
    "MSZoning_RM",

    "LotConfig_CulDSac",
    "LotConfig_FR2",
    "LotConfig_FR3",
    "LotConfig_Inside",

    "BldgType_2fmCon",
    "BldgType_Duplex",
    "BldgType_Twnhs",
    "BldgType_TwnhsE",
]

# =========================
# 2) RAW FEATURES TO EXTRACT
# =========================
RAW_FEATURES = [
    "MSSubClass",
    "MSZoning",
    "LotArea",
    "LotConfig",
    "BldgType",
    "OverallCond",
    "YearBuilt",
    "TotalBsmtSF",
]

# =========================
# 3) DEFAULTS (MEAN/MODE)
# =========================
DEFAULTS = {
    "MSSubClass": 20,
    "MSZoning": "RL",
    "LotArea": 9500,
    "LotConfig": "Inside",
    "BldgType": "1Fam",     # important: "1Fam" means all BldgType_* will be 0
    "OverallCond": 5,
    "YearBuilt": 1975,
    "TotalBsmtSF": 900,
}


# =========================
# 4) VALID CATEGORIES
# =========================
VALID_MSZONING = ["FV", "RH", "RL", "RM"]
VALID_LOTCONFIG = ["CulDSac", "FR2", "FR3", "Inside"]
VALID_BLDGTYPE = ["2fmCon", "Duplex", "Twnhs", "TwnhsE"]
# NOTE: if BldgType is "1Fam", then all one-hot columns = 0


# =========================
# GEMINI EXTRACTION
# =========================
def extract_features_from_prompt(prompt: str, gemini_api_key: str) -> dict:
    client = genai.Client(api_key=gemini_api_key)

    system_prompt = f"""
You are an information extraction engine.

Extract these house features from the user prompt and return ONLY valid JSON.

Required keys:
{RAW_FEATURES}

Rules:
- Return JSON only, no explanation.
- If a value is missing, set it to null.
- Use correct datatypes:
  - MSSubClass: int
  - LotArea: int
  - OverallCond: int
  - YearBuilt: int
  - TotalBsmtSF: float or int
  - MSZoning, LotConfig, BldgType: string
"""

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=system_prompt + "\n\nUSER PROMPT:\n" + prompt,
    )

    text = (response.text or "").strip()

    if text.startswith("```"):
        text = text.replace("```json", "").replace("```", "").strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {key: None for key in RAW_FEATURES}


# =========================
# HELPERS
# =========================
def safe_int(value, default):
    if value is None:
        return default
    try:
        return int(float(value))
    except:
        return default


def safe_float(value, default):
    if value is None:
        return default
    try:
        return float(value)
    except:
        return default


def safe_str(value, default):
    if value is None:
        return default
    value = str(value).strip()
    return value if value else default


def fill_missing(raw: dict) -> dict:
    """
    Fill missing values + enforce correct types.
    No None will remain.
    """

    clean = {}

    clean["MSSubClass"] = safe_int(raw.get("MSSubClass"), DEFAULTS["MSSubClass"])
    clean["LotArea"] = safe_int(raw.get("LotArea"), DEFAULTS["LotArea"])
    clean["OverallCond"] = safe_int(raw.get("OverallCond"), DEFAULTS["OverallCond"])
    clean["YearBuilt"] = safe_int(raw.get("YearBuilt"), DEFAULTS["YearBuilt"])
    clean["TotalBsmtSF"] = safe_float(raw.get("TotalBsmtSF"), DEFAULTS["TotalBsmtSF"])

    clean["MSZoning"] = safe_str(raw.get("MSZoning"), DEFAULTS["MSZoning"])
    clean["LotConfig"] = safe_str(raw.get("LotConfig"), DEFAULTS["LotConfig"])
    clean["BldgType"] = safe_str(raw.get("BldgType"), DEFAULTS["BldgType"])

    # If Gemini gives unknown category, fallback
    if clean["MSZoning"] not in VALID_MSZONING:
        clean["MSZoning"] = DEFAULTS["MSZoning"]

    if clean["LotConfig"] not in VALID_LOTCONFIG:
        clean["LotConfig"] = DEFAULTS["LotConfig"]

    # BldgType can be "1Fam" OR one of the dummy ones
    if clean["BldgType"] not in (["1Fam"] + VALID_BLDGTYPE):
        clean["BldgType"] = DEFAULTS["BldgType"]

    return clean


def build_one_hot_vector(clean: dict) -> np.ndarray:
    """
    Convert clean raw features into final 17-column one-hot encoded row.
    """

    row = {col: 0 for col in FINAL_FEATURE_ORDER}

    # numeric base
    row["MSSubClass"] = clean["MSSubClass"]
    row["LotArea"] = clean["LotArea"]
    row["OverallCond"] = clean["OverallCond"]
    row["YearBuilt"] = clean["YearBuilt"]
    row["TotalBsmtSF"] = clean["TotalBsmtSF"]

    # MSZoning one-hot
    # columns: FV, RH, RL, RM
    row[f"MSZoning_{clean['MSZoning']}"] = 1

    # LotConfig one-hot
    row[f"LotConfig_{clean['LotConfig']}"] = 1

    # BldgType one-hot
    # if 1Fam => all 0 (no dummy column for 1Fam)
    if clean["BldgType"] != "1Fam":
        row[f"BldgType_{clean['BldgType']}"] = 1

    # final ordered vector
    vector = [row[col] for col in FINAL_FEATURE_ORDER]
    return np.array(vector, dtype=float).reshape(1, -1)


def preprocess_prompt(prompt: str, gemini_api_key: str) -> np.ndarray:
    raw = extract_features_from_prompt(prompt, gemini_api_key)
    clean = fill_missing(raw)
    return build_one_hot_vector(clean)
